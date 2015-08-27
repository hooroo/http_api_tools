
require "active_support/core_ext/class/attribute"
require "active_support/json"
require 'active_support/core_ext/string/inflections'
require_relative 'relation_includes'
require_relative 'identity_map'
require_relative 'type_key_resolver'

module HttpApiTools
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
        unless excludes[attr_name]
          if self.respond_to?(attr_name)
            attribute_hash[attr_name] = self.send(attr_name)
          else
            attribute_hash[attr_name] = serializable.send(attr_name)
          end
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

    def exclude_whens
      self.class._exclude_whens
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

    def serializer_group
      self.class.serializer_group
    end

    def excludes
      @excludes ||= begin
        exclude_whens.keys.inject({}) do |result, attr_name|
          result[attr_name] = exclude?(attr_name)
          result
        end
      end
    end

    def exclude?(attr_name)
      exclude_when = exclude_whens[attr_name]

      if exclude_when.nil?
        false
      elsif exclude_when.is_a?(Symbol)
        send(exclude_when)
      elsif exclude_when.is_a?(Proc)
        instance_exec(serializable, &exclude_when)
      else
        raise "Attribute exclude_when must be configured with a symbol (method name) or a proc."
      end
    end

  end
end
