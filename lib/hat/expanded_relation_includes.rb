# Provides an expanded version of includes for use in queries where ids for has_many relationships are
# going to be referenced such as with the json serializer. Eradicates n+1 issues in these instances.
module Hat
  class ExpandedRelationIncludes

    def initialize(relation_includes, serializer)
      @relation_includes = relation_includes
      @serializer = serializer
    end

    def to_a
      @expanded_includes ||= begin
        expanded_includes = []
        expand_includes(serializer.class, relation_includes, expanded_includes)
        expanded_includes
      end
    end

    private

    attr_reader :serializer, :relation_includes

    def expand_includes(target_serializer_class, base_includes, expanded_includes)

      append_has_many_includes(target_serializer_class, base_includes, expanded_includes)

      base_includes.each do |include_item|
        if include_item.kind_of?(Symbol)
          expand_includes_for_symbol(include_item, target_serializer_class, expanded_includes)
        elsif include_item.kind_of?(Hash)
          expand_includes_for_hash(include_item, target_serializer_class, expanded_includes)
        end
      end

    end

    def expand_includes_for_symbol(include_item, target_serializer_class, expanded_includes)

      related_type = target_serializer_class.serializable_type.reflections[include_item].class_name.constantize
      related_serializer = SerializerRegistry.instance.get(target_serializer_class.serializer_type, related_type)
      new_nested_includes = []

      append_has_many_includes(related_serializer, [], new_nested_includes)

      if new_nested_includes.empty?
        expanded_includes << include_item
      else
        expanded_includes << { include_item => new_nested_includes }
      end

    end

    def expand_includes_for_hash(include_item, target_serializer_class, expanded_includes)

      nested_include_key = include_item.keys.first
      nested_includes = include_item[nested_include_key]

      related_type = target_serializer_class.serializable_type.reflections[nested_include_key].class_name.constantize
      related_serializer = SerializerRegistry.instance.get(target_serializer_class.serializer_type, related_type)
      new_nested_includes = []

      expanded_includes << { nested_include_key => new_nested_includes }
      expand_includes(related_serializer, nested_includes, new_nested_includes)

    end

    def append_has_many_includes(related_serializer, base_includes, expanded_includes)

      related_serializer.has_manys.each do |has_many_attr|
        expanded_includes << has_many_attr unless RelationIncludes.new(*base_includes).find(has_many_attr)
      end

    end


  end
end