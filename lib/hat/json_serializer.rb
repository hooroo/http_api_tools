require "active_support/core_ext/class/attribute"
require "active_support/json"
require 'active_support/core_ext/string/inflections'
require 'hat/relation_includes'
require 'hat/identity_map'
require 'hat/type_key_resolver'
require 'hat/json_serializer_dsl'

module Hat
  module JsonSerializer

    attr_reader :serializable, :relation_includes, :result, :attribute_mappings, :has_one_mappings, :has_many_mappings, :cached

    def initialize(serializable, attrs = {})
      @serializable = serializable
      @result = attrs[:result] || {}
      @relation_includes = attrs[:relation_includes] || RelationIncludes.new
      @identity_map = attrs[:identity_map] || IdentityMap.new
      @type_key_resolver = attrs[:type_key_resolver] || TypeKeyResolver.new
      @meta_data = { type: root_key.to_s.singularize, root_key: root_key.to_s }
    end

    def to_json(*args)
      JSON.fast_generate(as_json)
    end

    def as_json(*args)

      result[root_key] = []

      Array(serializable).each do |serializable_item|
        serialize_item_and_cache_relationships(serializable_item)
      end

      result[:meta] = meta_data.merge(includes_meta_data)
      result[:linked] = sideload_data_from_identity_map

      result
    end

    def includes(*includes)

      if includable
        allowable_includes_to_add = RelationIncludes.new(*includes) & includable
      else
        allowable_includes_to_add = includes
      end

      relation_includes.include(allowable_includes_to_add)

      self
    end

    def meta(data)
      meta_data.merge!(data)
      self
    end

    protected

    attr_accessor :identity_map

    def attributes
      self.class._attributes
    end

    def has_ones
      self.class.has_ones
    end

    def has_manys
      self.class.has_manys
    end


    def includable
      self.class._includable
    end

    def to_hash
      hash = attribute_hash.merge(links: has_one_hash.merge(has_many_hash))
      sideload_has_ones
      sideload_has_manys
      hash
    end

    private

    attr_writer :relation_includes
    attr_reader :type_key_resolver
    attr_accessor :serializer_map, :meta_data

    def includes_meta_data
      { includable: includable.to_s, included: relation_includes.to_s }
    end

    def serialize_item_and_cache_relationships(serializable_item)

      assert_id_present(serializable_item)

      serializer = serializer_for(serializable_item)
      hashed = { id: serializable_item.id }

      result[root_key] << hashed

      hashed.merge!(serializer.includes(*relation_includes.to_a).to_hash)

    end

    def attribute_hash

      attribute_hash = {}

      attributes.each do |attr_name|
        if self.respond_to? attr_name
          attribute_hash[attr_name] = self.send(attr_name)
        else
          attribute_hash[attr_name] = serializable.send(attr_name)
        end
      end

      attribute_hash

    end

    def has_one_hash

      has_one_hash = {}

      has_ones.each do |attr_name|

        id_attr = "#{attr_name}_id"

        #Use id attr if possible as it's cheaper than referencing the object
        if serializable.respond_to?(id_attr)
          related_id = serializable.send(id_attr)
        else
          related_id = serializable.send(attr_name).try(:id)
        end

        has_one_hash[attr_name] = related_id

      end

      has_one_hash

    end


    def has_many_hash

      has_many_hash = {}

      has_manys.each do |attr_name|
        has_many_relation = serializable.send(attr_name) || []
        has_many_hash[attr_name] = has_many_relation.map(&:id)
      end

      has_many_hash

    end

    def sideload_has_ones

      has_ones.each do |attr_name|

        if related_item = get_relation(attr_name)
          type_key = type_key_for(related_item)
          sideload_item(related_item, attr_name, type_key) unless identity_map.get(type_key, related_item.id)
        end

      end
    end

    def sideload_has_manys

      has_manys.each do |attr_name|

        if related_items = get_relation(attr_name)

          type_key = nil

          related_items.each do |related|
            type_key ||= type_key_for(related)
            sideload_item(related, attr_name, type_key) unless identity_map.get(type_key, related.id)
          end

        end
      end
    end

    def get_relation(attr_name)
      serializable.send(attr_name) if relation_includes.includes_relation?(attr_name)
    end

    def sideload_item(related, attr_name, type_key)
      serializer_class = serializer_class_for(related)
      includes = relation_includes.nested_includes_for(attr_name) || []
      hashed = serializer_class.new(related, { result: result, identity_map: identity_map, type_key_resolver: type_key_resolver }).includes(*includes).to_hash

      identity_map.put(type_key, related.id, hashed)
    end

    def sideload_data_from_identity_map
      identity_map.to_hash.inject({}) do |sideload_data, (key, type_map)|
        sideload_data[key] = type_map.values
        sideload_data
      end
    end

    def serializer_for(serializable_item)

      serializer_class = serializer_class_for(serializable_item)

      serializer_class.new(serializable_item, {
        result: result,
        identity_map: identity_map,
        type_key_resolver: type_key_resolver
      })

    end

    def serializer_class_for(model)
      "#{model.class.name}Serializer".constantize
    end

    def assert_id_present(serializable_item)
      raise "serializable items must have an id attribute" unless serializable_item.respond_to?(:id)
    end

    def root_key
      @_root_key ||= self.class.name.split("::").last.underscore.gsub('_serializer', '').pluralize.to_sym
    end

    def type_key_for(related)
      type_key_resolver.for_class(related.class)
    end

    #----Module Inclusion

    def self.included(base)

      base.class_attribute :_attributes
      base.class_attribute :_relationships
      base.class_attribute :_includable

      base._attributes = []
      base._relationships = { has_ones: [], has_manys: [] }

      base.extend(JsonSerializerDsl)

    end

  end
end


