require "active_support/core_ext/class/attribute"
require "active_support/json"
require 'active_support/core_ext/string/inflections'
require_relative '../base_json_serializer'

module Hat
  module Nesting
    module JsonSerializer

      include Hat::BaseJsonSerializer

      def as_json(*args)

        result[root_key] = Array(serializable).map do |serializable_item|
          serialize_nested_item_with_includes(serializable_item, relation_includes)
        end

        result[:meta] = meta_data.merge(includes_meta_data)

        result
      end

      protected

      def serialize
        attribute_hash.merge(has_one_hash).merge(has_many_hash)
      end

      private

      def has_one_hash

        has_one_hash = {}

        has_ones.each do |attr_name|

          id_attr = "#{attr_name}_id"

          if related_item = get_relation(attr_name)
            has_one_hash[attr_name] = serialize_nested_item_with_includes(related_item, includes_for_attr(attr_name))
          elsif serializable.respond_to?(id_attr)
            has_one_hash[id_attr] = serializable.send(id_attr)
          else
            has_one_hash[id_attr] = serializable.send(attr_name).try(:id)
          end
        end

        has_one_hash

      end


      def has_many_hash

        has_many_hash = {}

        has_manys.each do |attr_name|
          if related_items = get_relation(attr_name)
            has_many_hash[attr_name] = related_items.map do |related_item|
              serialize_nested_item_with_includes(related_item, includes_for_attr(attr_name))
            end
          else
            has_many_relation = serializable.send(attr_name) || []
            has_many_hash["#{attr_name.to_s.singularize}_ids"] = has_many_relation.map(&:id)
          end
        end

        has_many_hash

      end

      def get_relation(attr_name)
        serializable.send(attr_name) if relation_includes.includes_relation?(attr_name)
      end

      def serialize_nested_item_with_includes(serializable_item, includes)

        assert_id_present(serializable_item)

        serializer = serializer_for(serializable_item)
        hashed = { id: serializable_item.id }

        hashed.merge(serializer.includes(*includes).serialize)

      end

      def includes_for_attr(attr_name)
        relation_includes.nested_includes_for(attr_name) || []
      end

      def serializer_for(serializable_item)

        serializer_class_for(serializable_item).new(serializable_item, {
          result: {}
        })

      end

      def serializer_class_for(serializable)
        Hat::SerializerRegistry.instance.get(:nesting, serializable.class)
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
