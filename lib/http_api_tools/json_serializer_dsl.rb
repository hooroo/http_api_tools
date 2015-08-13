require_relative 'serializer_registry'

module HttpApiTools
  module JsonSerializerDsl

    def self.apply_to(serializer_class)
      serializer_class.class_attribute :_attributes
      serializer_class.class_attribute :_relationships
      serializer_class.class_attribute :_includable
      serializer_class.class_attribute :_serializes
      serializer_class.class_attribute :_group
      serializer_class.class_attribute :_exclude_whens

      serializer_class._attributes = []
      serializer_class._relationships = { has_ones: [], has_manys: [] }
      serializer_class._exclude_whens = {}

      serializer_class.extend(self)
    end

    def serializes(klass, options = {})
      group = options[:group] || :default
      self._serializes = klass
      self._group = group
      HttpApiTools::SerializerRegistry.instance.register(serializer_type, group, klass.name, self)
    end

    def serializable_type
      self._serializes
    end

    def serializer_group
      self._group
    end

    def has_ones
      self._relationships[:has_ones]
    end

    def has_manys
      self._relationships[:has_manys]
    end

    def attributes(*args)
      args.each {|attr_name| attribute(attr_name) }
    end

    def attribute(attr_name, exclude_when: nil)
      self._attributes << attr_name
      self._exclude_whens[attr_name] = exclude_when unless exclude_when.nil?
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
