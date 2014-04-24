require 'active_support/core_ext'

# Hopefully the spec is robust enough that we can
# break this down and refactor as we go. I'm not
# happy with the complexity of it, but it's a
# reasonably complex problem
# ~ Stu

module Hat
  class RelationIncludes < SimpleDelegator
    include Comparable

    def initialize(*includes)
      @includes = includes.compact
      super(@includes)
    end

    def self.from_params(params)
      from_string(params[:include])
    end

    def self.from_string(string)
      return new if string.blank?

      includes_hash = build_hash_from_string(string)
      new(*flatten(includes_hash))
    end

    def for_serializable_model(model_class)

      new_includes = []
      original_includes = self.to_a

      append_deep_relation_includes_for(model_class, original_includes, new_includes)

      RelationIncludes.new(*new_includes)
    end

    def append_deep_relation_includes_for(model_class, original_includes, new_includes)

      serializer = "#{model_class.name}Serializer".constantize
      has_manys = serializer.has_manys
      has_ones = serializer.has_ones

      has_manys.each do |has_many_name|
        new_includes << has_many_name unless RelationIncludes.new(*original_includes).find(has_many_name)#.empty?
      end

      original_includes.each do |include_item|
        if include_item.kind_of?(Symbol)

          related_model_class = model_class.reflections[include_item].class_name.constantize

          new_nested_includes = []
          new_includes << { include_item => new_nested_includes }

          append_deep_relation_includes_for(related_model_class, [], new_nested_includes)

        elsif include_item.kind_of?(Hash)

          nested_include_key = include_item.keys.first
          nested_includes = include_item[nested_include_key]

          related_model_class = model_class.reflections[nested_include_key].class_name.constantize

          new_nested_includes = []
          new_includes << { nested_include_key => new_nested_includes }

          append_deep_relation_includes_for(related_model_class, nested_includes, new_nested_includes)
        end
      end

    end

    def to_s
      @to_s ||= begin
        paths = []
        includes.each do |item|
          if item.is_a? Hash
            stringify_keys(paths, item)
          else
            paths << [item]
          end
        end
        paths = paths.map { |p| p.join('.') }
        paths.sort.join(',')
      end
    end

    def &(other_includes)
      hash = self.class.build_hash_from_string(to_s)
      other_hash = self.class.build_hash_from_string(other_includes.to_s)

      intersected_paths = (to_s.split(',') & other_includes.to_s.split(','))
      self.class.from_string(intersected_paths.join(','))
    end

    def <=>(other_includes)
      to_s <=> other_includes.to_s
    end

    def include(additional_includes)
      includes.concat(additional_includes)
      self
    end

    def includes_relation?(attr_name)
      find(attr_name).present?
    end

    def find(attr_name)
      includes.find do |relation|
        (relation.kind_of?(Symbol) && attr_name == relation) ||
          (relation.kind_of?(Hash) && relation.keys.include?(attr_name))
      end
    end

    def nested_includes_for(attr_name)
      nested = find(attr_name)
      if nested.kind_of?(Hash)
        nested[attr_name]
      end
    end

    protected



    private

    attr_accessor :includes

    def self.build_hash_from_string(string)
      includes_hash = {}
      include_paths = string.split(',').map { |path| path.split('.') }

      include_paths.each do |path|
        current_hash = includes_hash
        path.each do |token|
          current_hash[token] ||= {}
          current_hash = current_hash[token]
        end
      end
      includes_hash
    end

    def stringify_keys(top_level_paths, hash, path_attrs = [])
      current_key = hash.keys.first
      path_attrs << current_key
      top_level_paths << path_attrs.dup

      hash[current_key].each do |path_value|
        if path_value.is_a? Hash
          path_attrs << stringify_keys(top_level_paths, path_value, path_attrs)
        else
          top_level_paths << (path_attrs.dup << path_value)
        end
      end
    end

    # Turns this:
    #
    # [ :tags, {images: [:comments]}, {reviews: [:author]} ]
    #
    # Into this:
    #
    #   {
    #     tags: {},
    #     images: {
    #       comments: {}
    #     }
    #     reviews: {}
    #     }
    #   }
    #
    def self.flatten(hash)
      result = []
      hash.each do |k, v|
        if v.keys.size == 0
          result << k.to_sym
        else
          result << { "#{k}".to_sym => flatten(v) }
        end
      end
      result
    end

  end
end