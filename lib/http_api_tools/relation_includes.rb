require 'http_api_tools/expanded_relation_includes'

# Hopefully the spec is robust enough http_api_tools we can
# break this down and refactor as we go. I'm not
# happy with the complexity of it, but it's a
# reasonably complex problem
# ~ Stu

module HttpApiTools
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

    def to_s
      @to_s ||= begin
        paths = []

        includes.each { |item| create_path_matrix(paths, item, path_attrs = []) }

        joined_paths = paths.map { |p| p.join('.') }
        joined_paths.sort.join(',')

      end
    end

    def create_path_matrix(top_level_paths, item, path_attrs = [])

      if item.is_a?(Hash)
        current_key = item.keys.first
        path_attrs << current_key
        top_level_paths << path_attrs

        item[current_key].each do |path_value|
          create_path_matrix(top_level_paths, path_value, path_attrs.dup)
        end
      else
        top_level_paths << (path_attrs << item)
      end

    end

    def &(other_includes)
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

    def for_query(serializer_class)
      RelationIncludes.new(*ExpandedRelationIncludes.new(self, serializer_class))
    end

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