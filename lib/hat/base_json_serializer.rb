
require "active_support/core_ext/class/attribute"
require "active_support/json"
require 'active_support/core_ext/string/inflections'
require_relative 'relation_includes'
require_relative 'identity_map'
require_relative 'type_key_resolver'

module Hat
  module BaseJsonSerializer

    attr_reader :serializable, :relation_includes

    def initialize(serializable, attrs = {})
      @serializable = serializable
      @relation_includes = attrs[:relation_includes] || RelationIncludes.new
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

    private

    attr_writer :relation_includes
    attr_reader :type_key_resolver
    attr_accessor :serializer_map, :meta_data

    def includes_meta_data
      { includable: includable.to_s, included: relation_includes.to_s }
    end

  end
end
