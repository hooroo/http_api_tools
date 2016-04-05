module HttpApiTools
  module RootKeyable

    protected

    def root_key
      class_variable_memoize(:@@root_key) do
        self.class._serializes.name.split("::").last.underscore.pluralize.freeze.to_sym
      end
    end

    def root_type
      class_variable_memoize(:@@root_type) do
        self.class.class_variable_set(:@@root_type, root_key.to_s.singularize.freeze)
      end
    end

    private

    def class_variable_memoize(key, &block)
      unless self.class.class_variable_defined?(key)
        self.class.class_variable_set(key, block.call)
      end
      self.class.class_variable_get(key)
    end

  end
end
