
require "active_support/core_ext/class/attribute"
require "active_support/json"
require 'active_support/core_ext/string/inflections'
require_relative 'relation_includes'
require_relative 'identity_map'
require_relative 'type_key_resolver'

module Hat
  module BaseJsonSerializer

    attr_reader :serializable, :relation_includes, :result, :meta_data

    def initialize(serializable, attrs = {})
      @serializable = serializable
      @relation_includes = attrs[:relation_includes] || RelationIncludes.new
      @result = attrs[:result] || {}
      @meta_data = { type: root_key.to_s.singularize, root_key: root_key.to_s }
    end


    def attribute_hash

      attribute_hash = {}

      attributes.each do |attr_name|
        if self.respond_to?(attr_name)
          attribute_hash[attr_name] = self.send(attr_name)
        else
          attribute_hash[attr_name] = serializable.send(attr_name)
        end
      end

      attribute_hash

    end


    def to_json(*args)
      JSON.fast_generate(as_json)
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

    protected

    attr_accessor :identity_map

    private

    attr_writer :relation_includes
    attr_reader :type_key_resolver
    attr_accessor :serializer_map, :meta_data

    def root_key
      @_root_key ||= self.class._serializes.name.split("::").last.underscore.pluralize.to_sym
    end

    def includes_meta_data
      {
        includable: includable.to_s.blank? ? '*' : includable.to_s,
        included: relation_includes.to_s
      }
    end

    def assert_id_present(serializable_item)
      raise "serializable items must have an id attribute" unless serializable_item.respond_to?(:id)
    end

  end
end
