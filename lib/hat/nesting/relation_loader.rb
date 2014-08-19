module Hat
  module Nesting
    class Relationloader

      def initialize(opts = {})
        @serializable = opts[:serializable]
        @has_ones = opts[:has_ones]
        @has_manys = opts[:has_manys]
        @relation_includes = opts[:relation_includes]
      end

      def relation_hash
        has_one_hash.merge(has_many_hash)
      end

      private

      attr_reader :serializable, :has_ones, :has_manys, :relation_includes

      def has_one_hash
        has_ones.inject({}) { |has_one_hash, attr_name| serialize_has_one_relation(has_one_hash, attr_name) }
      end

      def serialize_has_one_relation(has_one_hash, attr_name)

        id_attr = "#{attr_name}_id"

        if related_item = relation_for(attr_name)
          has_one_hash[attr_name] = serialize_nested_item_with_includes(related_item, includes_for_attr(attr_name))
        elsif serializable.respond_to?(id_attr)
          has_one_hash[id_attr] = serializable.send(id_attr)
        else
          has_one_hash[id_attr] = serializable.send(attr_name).try(:id)
        end

        has_one_hash

      end


      def has_many_hash
        has_manys.inject({}) { |has_many_hash, attr_name| serialize_has_many_relations(has_many_hash, attr_name) }
      end

      def serialize_has_many_relations(has_many_hash, attr_name)
        if related_items = relation_for(attr_name)
          has_many_hash[attr_name] = related_items.map do |related_item|
            serialize_nested_item_with_includes(related_item, includes_for_attr(attr_name))
          end
        else
          has_many_relation = serializable.send(attr_name) || []
          has_many_hash["#{attr_name.to_s.singularize}_ids"] = has_many_relation.map(&:id)
        end

        has_many_hash

      end

      def relation_for(attr_name)
        serializable.send(attr_name) if relation_includes.includes_relation?(attr_name)
      end

      def serialize_nested_item_with_includes(serializable_item, includes)

        serializer = serializer_for(serializable_item)

        serializer.includes(*includes).serialize

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

    end
  end
end