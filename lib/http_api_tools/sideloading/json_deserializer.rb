# encoding: utf-8

# Takes a sideloaded json response and builds an object graph with cyclic
# relationships using models defined using HttpApiTools::Attribute mappings.

require 'active_support/core_ext/hash/indifferent_access'
require_relative 'sideload_map'
require_relative '../identity_map'

module HttpApiTools
  module Sideloading
    class JsonDeserializer

      def initialize(json, opts = { namespace: nil })
        @json = json
        @root_key = json['meta']['root_key'].to_s
        @identity_map = IdentityMap.new
        @sideload_map = SideloadMap.new(json, root_key)
        @key_to_class_mappings = {}
        @namespace = opts[:namespace] || NullNamespace.new
      end

      def deserialize
        json[root_key].map do |json_item|
          create_from_json_item(target_class_for_key(root_key), json_item)
        end
      end

      private

      attr_accessor :json, :root_key, :sideload_map, :identity_map, :key_to_class_mappings
      attr_reader :namespace

      def create_from_json_item(target_class, json_item)

        return nil unless target_class

        existing_deserialized = identity_map.get(target_class.name, json_item['id'])
        return existing_deserialized if existing_deserialized

        relations = {}
        target_class_name = target_class.name

        #we have to add this before we process subtree or we'll get circular issues
        target = target_class.new(json_item.with_indifferent_access)
        identity_map.put(target_class_name, json_item['id'], target)

        links = json_item['links'] || {}

        apply_has_many_relations_to_target(target, links)
        apply_belongs_to_relations_to_target(target, links)

        target

      end

      def apply_has_many_relations_to_target(target, links)

        target.class.has_many_relations.keys.each do |relation_name|

          relation_name = relation_name.to_s

          if links.has_key?(relation_name)
            linked_ids = links[relation_name]
            target.send("#{relation_name}=", create_has_manys(target.class.name, relation_name, linked_ids))
            target.send("#{relation_name.singularize}_ids=", linked_ids)
          end

        end
      end

      def apply_belongs_to_relations_to_target(target, links)

        target.class.belongs_to_relations.keys.each do |relation_name|

          relation_name = relation_name.to_s

          if links.has_key?(relation_name)
            linked_id = links[relation_name.to_s]
            target.send("#{relation_name}=", create_belongs_to(target.class.name, relation_name, linked_id))
            target.send("#{relation_name}_id=", linked_id)
          end

        end
      end

      def create_belongs_to(parent_class_name, sideload_key, id)

        sideload_key = mapped_sideload_key_for(parent_class_name, sideload_key)

        if sideloaded_json = sideload_map.get(sideload_key, id)
          sideloaded_object = create_from_json_item(target_class_for_key(sideload_key), sideloaded_json)
        else
          nil
        end
      end

      def create_has_manys(parent_class_name, sideload_key, ids)
        sideload_key = mapped_sideload_key_for(parent_class_name, sideload_key)
        target_class = target_class_for_key(sideload_key)
        sideloaded_json_items = sideload_map.get_all(sideload_key, ids)

        sideloaded_json_items.map do |json_item|
          create_from_json_item(target_class, json_item)
        end
      end

      def mapped_sideload_key_for(parent_class_name, sideload_key)

        resolve_class_mappings_for(parent_class_name)
        class_mapping = key_to_class_mappings[parent_class_name]

        if attribute_mapping = class_mapping[sideload_key.to_sym]
          return attribute_mapping.name.split('::').last.underscore
        end

        sideload_key
      end

      def resolve_class_mappings_for(parent_class_name)
        unless key_to_class_mappings[parent_class_name]

          mapping_class_name = "#{parent_class_name}DeserializerMapping"

          if Object.const_defined?(mapping_class_name)
            key_to_class_mappings[parent_class_name] = mapping_class_name.constantize.mappings
          else
            key_to_class_mappings[parent_class_name] = {}
          end
        end
      end

      def target_class_for_key(key)
        [namespace.name, key.to_s.singularize.camelize].compact.join('::').constantize
      rescue NameError
        nil
      end

      class NullNamespace
        def name
          nil
        end
      end

    end
  end
end
