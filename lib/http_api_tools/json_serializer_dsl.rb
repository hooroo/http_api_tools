require_relative 'serializer_registry'

module HttpApiTools
  module JsonSerializerDsl

    def self.apply_to(serializer_class)
      serializer_class.class_attribute :_attributes
      serializer_class.class_attribute :_relationships
      serializer_class.class_attribute :_includable
      serializer_class.class_attribute :_serializes

      serializer_class._attributes = []
      serializer_class._relationships = { has_ones: [], has_manys: [] }

      serializer_class.extend(self)
    end

    def serializes(klass)
      self._serializes = klass
      HttpApiTools::SerializerRegistry.instance.register(serializer_type, klass.name, self)
    end

    def serializable_type
      self._serializes
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

    def serializer_type
      if self.ancestors.any? { |klass| klass == HttpApiTools::Sideloading::JsonSerializer }
        :sideloading
      elsif self.ancestors.any? { |klass| klass == HttpApiTools::Nesting::JsonSerializer }
        :nesting
      else
        raise "Unsupported serializer_type. Must be one of either 'sideloading' or 'nesting' serializer."
      end
    end

  end
end
