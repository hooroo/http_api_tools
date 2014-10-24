#Provides a cache for resolved type keys against classes. When serializing a lot of
#relationships this can have a significant improvement on performance.

module HttpApiTools
  class TypeKeyResolver

    def initialize
      @cache = {}
    end

    def for_class(klass)
      class_name = klass.name
      cache[class_name] || resolve_and_store_type_key_for(class_name)
    end

    private

    attr_reader :cache

    def resolve_and_store_type_key_for(class_name)
      type_key = class_name.underscore.pluralize
      cache[class_name] = type_key
      type_key
    end

  end
end