require "active_support/core_ext/class/attribute"
require "active_support/json"
require 'active_support/core_ext/string/inflections'
require_relative '../base_json_serializer'

module Hat
  module Nesting
    module JsonSerializer

      include Hat::BaseJsonSerializer

      private

      #----Module Inclusion
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
