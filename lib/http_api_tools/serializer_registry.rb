require 'singleton'
require 'http_api_tools/serializer_loader'

module HttpApiTools
  class SerializerRegistry

    include Singleton

    def get(type, group, class_name)
      registry.fetch(type.to_sym, {}).fetch(group, {})[class_name]
    end

    def register(type, group, class_name, serializer)
      grouped_serializers = registry[type.to_sym][group] ||= {}
      grouped_serializers[class_name] = serializer
    end

    private

    def registry
      @registry ||= { sideloading: {}, nesting: {} }
    end

  end
end


