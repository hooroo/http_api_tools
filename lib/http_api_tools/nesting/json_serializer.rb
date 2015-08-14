require "active_support/core_ext/class/attribute"
require "active_support/json"
require 'active_support/core_ext/string/inflections'
require_relative '../base_json_serializer'
require_relative 'relation_loader'

module HttpApiTools
  module Nesting
    module JsonSerializer

      include HttpApiTools::BaseJsonSerializer

      def as_json(*args)

        result[root_key] = Array(serializable).map do |serializable_item|
          serializer = self.class.new(serializable_item, { result: {} })
          serializer.includes(*relation_includes).serialize
        end

        result.merge({ meta: meta_data.merge(includes_meta_data) })
      end

      def serialize
        attribute_hash.merge(relation_loader.relation_hash)
      end

      private

      def relation_loader
        @relation_loader ||= Relationloader.new({
          serializer_group: serializer_group,
          serializable: serializable,
          has_manys: has_manys,
          has_ones: has_ones,
          relation_includes: relation_includes,
          excludes: excludes
        })
      end

      def self.included(serializer_class)
        JsonSerializerDsl.apply_to(serializer_class)
      end

    end
  end
end
