require_relative '../base_json_serializer'
require_relative '../json_serializer_dsl'
require_relative 'relation_sideloader'

module Hat
  module Sideloading
    module JsonSerializer

      include Hat::BaseJsonSerializer

      attr_reader :relation_includes, :result, :attribute_mappings, :has_one_mappings, :has_many_mappings, :cached

      def initialize(serializable, attrs = {})
        super
        @identity_map = attrs[:identity_map] || IdentityMap.new
        @type_key_resolver = attrs[:type_key_resolver] || TypeKeyResolver.new
      end

      def as_json(*args)

        result[root_key] = []

        Array(serializable).each do |serializable_item|
          serialize_item_and_cache_relationships(serializable_item)
        end

        result.merge({ meta: meta_data.merge(includes_meta_data), linked: relation_sideloader.as_json })
      end

      def as_sideloaded_hash
        hash = attribute_hash.merge(links: has_one_hash.merge(has_many_hash))
        relation_sideloader.sideload_relations
        hash
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

      attr_reader :relation_sideloader

      def serialize_item_and_cache_relationships(serializable_item)

        assert_id_present(serializable_item)

        serializer = serializer_for(serializable_item)
        hashed = { id: serializable_item.id }

        result[root_key] << hashed

        hashed.merge!(serializer.includes(*relation_includes.to_a).as_sideloaded_hash)

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

      def relation_sideloader
        @relation_sideloader ||= RelationSideloader.new(
          serializable: serializable,
          has_ones: has_ones,
          has_manys: has_manys,
          relation_includes: relation_includes,
          identity_map: identity_map,
          type_key_resolver: type_key_resolver,
          result: result
        )
      end

      def serializer_for(serializable_item)

        serializer_class = serializer_class_for(serializable_item)

        serializer_class.new(serializable_item, {
          result: result,
          identity_map: identity_map,
          type_key_resolver: type_key_resolver
        })

      end

      def serializer_class_for(serializable)
        Hat::SerializerRegistry.instance.get(:sideloading, serializable.class)
      end

      def self.included(serializer_class)
        JsonSerializerDsl.apply_to(serializer_class)
      end

    end
  end
end

