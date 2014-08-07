# Provides an expanded version of includes for use in queries where ids for relationships are
# going to be referenced such as with the json serializer. Eradicates n+1 issues.
module Hat
  class ExpandedRelationIncludes

    def initialize(relation_includes, model_class)
      @relation_includes = relation_includes
      @model_class = model_class
    end

    def to_a
      @expanded_includes ||= begin
        expanded_includes = []
        expand_includes(model_class, relation_includes, expanded_includes)
        expanded_includes
      end
    end

    private

    attr_reader :model_class, :relation_includes

    def expand_includes(target_model_class, base_includes, expanded_includes)

      append_has_many_includes(target_model_class, base_includes, expanded_includes)

      base_includes.each do |include_item|
        if include_item.kind_of?(Symbol)
          expand_includes_for_symbol(include_item, target_model_class, expanded_includes)
        elsif include_item.kind_of?(Hash)
          expand_includes_for_hash(include_item, target_model_class, expanded_includes)
        end
      end

    end

    def expand_includes_for_symbol(include_item, target_model_class, expanded_includes)

      related_model_class = target_model_class.reflections[include_item].class_name.constantize
      new_nested_includes = []

      expanded_includes << { include_item => new_nested_includes }
      append_has_many_includes(related_model_class, [], new_nested_includes)

    end

    def expand_includes_for_hash(include_item, target_model_class, expanded_includes)

      nested_include_key = include_item.keys.first
      nested_includes = include_item[nested_include_key]
      related_model_class = target_model_class.reflections[nested_include_key].class_name.constantize
      new_nested_includes = []

      expanded_includes << { nested_include_key => new_nested_includes }
      expand_includes(related_model_class, nested_includes, new_nested_includes)

    end

    def append_has_many_includes(target_model_class, base_includes, expanded_includes)

      #TODO - remove hardcoding to sideloading serializer
      serializer = Hat::SerializerRegistry.instance.get(:sideloading, target_model_class)

      serializer.has_manys.each do |has_many_attr|
        expanded_includes << has_many_attr unless RelationIncludes.new(*base_includes).find(has_many_attr)
      end

    end


  end
end