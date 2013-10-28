module Hat
  class RelationIncludes

    attr_reader :includes

    def initialize(includes)
      @includes = includes || []
    end

    def include(additional_includes)
      @includes.concat(additional_includes)
      self
    end

    def include?(attr_name)
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
  end
end