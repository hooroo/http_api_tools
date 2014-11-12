require 'singleton'
require 'http_api_tools/serializer_loader'

module HttpApiTools
  class SerializerRegistry

    include Singleton

    def get(type, class_name)
      registry.fetch(type.to_sym, {})[class_name]
    end

    def register(type, class_name, serializer)
      registry[type.to_sym][class_name] = serializer
    end

    private

    def registry
      @registry ||= { sideloading: {}, nesting: {} }
    end

  end
end


