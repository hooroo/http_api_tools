require_relative 'serializer_registry'

module Hat
  module JsonSerializerDsl

    def serializes(klass)
      self._serializes = klass
      Hat::SerializerRegistry.instance.register(type, klass, self)
    end

    def has_ones
      self._relationships[:has_ones]
    end

    def has_manys
      self._relationships[:has_manys]
    end

    def attributes(*args)
      self._attributes = args
    end

    def has_one(has_one)
      self.has_ones << has_one
    end

    def has_many(has_many)
      self.has_manys << has_many
    end

    def includable(*includes)
      self._includable = RelationIncludes.new(*includes)
    end

    def type
      raise 'define type of serializer (sideloading|nesting)'
    end

  end
end
