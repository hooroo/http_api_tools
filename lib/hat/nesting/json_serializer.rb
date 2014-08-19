require "active_support/core_ext/class/attribute"
require "active_support/json"
require 'active_support/core_ext/string/inflections'
require_relative '../base_json_serializer'
require_relative 'relation_loader'

module Hat
  module Nesting
    module JsonSerializer

      include Hat::BaseJsonSerializer

      def as_json(*args)

        result[root_key] = Array(serializable).map do |serializable_item|
          serializer = self.class.new(serializable_item, {
            result: {}
          })

          serializer.includes(*relation_includes).serialize
        end

        result[:meta] = meta_data.merge(includes_meta_data)

        result
      end

      def serialize
        assert_id_present(serializable)
        attribute_hash.merge(relation_loader.relation_hash)
      end

      private

      def relation_loader
        @relation_loader ||= Relationloader.new({
          serializable: serializable,
          has_manys: has_manys,
          has_ones: has_ones,
          relation_includes: relation_includes
        })
      end

      #----Module Inclusion
      #-- TODO figure out how to pull this up a level to DRY things up
      def self.included(base)
        base.class_attribute :_attributes
        base.class_attribute :_relationships
        base.class_attribute :_includable
        base.class_attribute :_serializes

        base._attributes = []
        base._relationships = { has_ones: [], has_manys: [] }

        base.extend(JsonSerializerDsl)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def type
          :nesting
        end
      end

    end
  end
end
