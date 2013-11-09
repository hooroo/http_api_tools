module Hat
  class RelationIncludes

    include Enumerable

    attr_reader :includes

    def initialize(includes)
      @includes = includes || []
    end

    def each(&block)
      includes.each(&block)
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

    def self.from_params(params)

      includes_hash = {}
      include_str = params[:include] || ''
      include_paths = include_str.split(',').map { |include_path| include_path.split('.') }

      include_paths.each do |path|
        current_hash = includes_hash
        path.each do |token|
          current_hash[token] ||= {}
          current_hash = current_hash[token]
        end
      end

      self.new(flatten(includes_hash))
    end

    private

    def self.flatten(hash)
      result = []
      hash.each do |k, v|
        if v.keys.size == 0
          result << k.to_sym
        else
          result << {"#{k}".to_sym => flatten(v) }
        end
      end
      result
    end

  end
end