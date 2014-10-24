module HttpApiTools
  module Sideloading
    class RelationSideloader

      def initialize(opts = {})
        @serializable = opts[:serializable]
        @has_ones = opts[:has_ones]
        @has_manys = opts[:has_manys]
        @relation_includes = opts[:relation_includes]
        @result = opts[:result]
        @identity_map = opts[:identity_map]
        @type_key_resolver = opts[:type_key_resolver]
      end

      def sideload_relations
        sideload_has_ones
        sideload_has_manys
      end

      def as_json
        identity_map.to_hash.inject({}) do |sideload_data, (key, type_map)|
          sideload_data[key] = type_map.values
          sideload_data
        end
      end

      private

      attr_reader :serializable, :has_ones, :has_manys, :relation_includes, :identity_map, :type_key_resolver, :result

      def sideload_has_ones

        has_ones.each do |attr_name|
          if related_item = relation_for(attr_name)
            type_key = type_key_for(related_item)
            sideload_item(related_item, attr_name, type_key) unless identity_map.get(type_key, related_item.id)
          end
        end
      end

      def sideload_has_manys

        has_manys.each do |attr_name|

          if related_items = relation_for(attr_name)
            type_key = nil
            related_items.each do |related_item|
              type_key ||= type_key_for(related_item)
              sideload_item(related_item, attr_name, type_key) unless identity_map.get(type_key, related_item.id)
            end
          end
        end
      end


      def relation_for(attr_name)
        serializable.send(attr_name) if relation_includes.includes_relation?(attr_name)
      end

      def sideload_item(related, attr_name, type_key)
        serializer_class = serializer_class_for(related)
        includes = relation_includes.nested_includes_for(attr_name) || []
        sideloaded_hash = serializer_class.new(related, { result: result, identity_map: identity_map, type_key_resolver: type_key_resolver }).includes(*includes).as_sideloaded_hash

        identity_map.put(type_key, related.id, sideloaded_hash)
      end

      def type_key_for(related)
        type_key_resolver.for_class(related.class)
      end

      def serializer_class_for(serializable)
        HttpApiTools::SerializerRegistry.instance.get(:sideloading, serializable.class)
      end


    end
  end
end