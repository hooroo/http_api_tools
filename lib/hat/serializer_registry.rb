require 'singleton'

module Hat
  class SerializerRegistry

    include Singleton

    def get(type, class_name)
      registry.fetch(type.to_sym, {})[class_name]
    end

    def register(type, class_name, serializer)
      if existing_serializer = get(type, class_name)
        raise "A '#{type}' serializer for '#{class_name}' instances has already been registered as #{existing_serializer.name}"
      else
        registry[type.to_sym][class_name] = serializer
      end
    end

    private

    def registry
      @registry ||= { sideloading: {}, nested: {} }
    end

  end
end
