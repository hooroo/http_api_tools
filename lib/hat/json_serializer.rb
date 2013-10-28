require "active_support/core_ext/class/attribute"
require "active_support/json"

module Hat
  module JsonSerializer

    attr_reader :serializable, :relation_includes, :result, :attribute_mappings, :has_one_mappings, :has_many_mappings, :cached

    def initialize(serializable, options = {})
      @serializable = serializable
      @result = options[:result] || {}
      @relation_includes = options[:relation_includes] || RelationIncludes.new([])
    end

    def to_json(*args)

      if serializable.kind_of?(Array) || is_active_record_relation?(serializable)
        root_key = root_key_for_collection
        result[root_key] = []
        serializable.each do |serializable_item|
          serializer_class = serializer_class_for(serializable_item)
          hashed = { id: serializable_item.id }
          result[root_key] << hashed
          hashed.merge! serializer_class.new(serializable_item, result: result).includes(*relation_includes.includes).to_hash
        end
      else
        serialized_hash = to_hash
        root_key = root_key_for_item(serializable)
        result[root_key] = serialized_hash
      end

      result[:meta] = {
        type: root_key.to_s.singularize,
        root_key: root_key
      }

      JSON.fast_generate(result)

    end

    def includes(*includes)
      self.relation_includes.include(includes)
      self
    end

    protected

    def attributes
      self.class._attributes
    end

    def has_ones
      self.class._relationships[:has_ones]
    end

    def has_manys
      self.class._relationships[:has_manys]
    end

    def to_hash

      hash = attribute_hash.merge(has_one_hash).merge(has_many_hash)

      sideload_has_ones
      sideload_has_manys

      hash
    end

    private

    attr_writer :relation_includes

    def attribute_hash

      attribute_hash = {}

      attributes.each do |attr_name|
        if self.respond_to? attr_name
          attribute_hash[attr_name] = self.send(attr_name)
        else
          attribute_hash[attr_name] = serializable.send(attr_name)
        end
      end

      attribute_hash

    end

    def has_one_hash

      has_one_hash = {}

      has_ones.each do |attr_name|

        id_attr = "#{attr_name}_id".to_sym

        #Use id attr if possible as it's cheaper than referencing the object
        if serializable.respond_to? id_attr
          related_id = serializable.send(id_attr)
        else
          related_id = serializable.send(attr_name).try(:id)
        end

        has_one_hash[id_attr] = related_id

      end

      has_one_hash

    end


    def has_many_hash

      has_many_hash = {}

      has_manys.each do |attr_name|
        has_many_relation = serializable.send("#{attr_name}") || []
        has_many_hash["#{attr_name.to_s.singularize}_ids".to_sym] = has_many_relation.map(&:id)
      end

      has_many_hash

    end

    def sideload_has_ones

      has_ones.each do |attr_name|

        id_attr = "#{attr_name}_id".to_sym

        if relation_includes.include?(attr_name)

          if related = serializable.send(attr_name)

            relation_json_key = attr_name.to_s.pluralize.to_sym

            unless hashed_relations = result[relation_json_key]
              hashed_relations = result[relation_json_key] = []
            end

            unless hashed_relations.find { |relation| relation[:id] == related.id }
              related = serializable.send("#{attr_name}")
              serializer_class = serializer_class_for(related)
              #Need to add before serializing otherwise we'll get into infinite loops with cyclic dependencies
              hashed = { id: related.id}
              hashed_relations << hashed
              includes = relation_includes.nested_includes_for(attr_name) || []
              hashed.merge! serializer_class.new(related, result: result).includes(*includes).to_hash
            end
          end
        end
      end
    end

    def sideload_has_manys

      has_manys.each do |attr_name|
        if relation_includes.include?(attr_name)

          unless hashed_relations = result[attr_name.to_s.pluralize.to_sym]
            hashed_relations = result[attr_name.to_s.pluralize.to_sym] = []
          end

          has_many_relation = serializable.send("#{attr_name}") || []

          has_many_relation.each do |related|
            #Probably want to use the identity map from the deserializer for this
            unless hashed_relations.find {|relation| relation[:id] == related.id}
              serializer_class = serializer_class_for(related)
              includes = relation_includes.nested_includes_for(attr_name) || []
              hashed = serializer_class.new(related, result: result).includes(*includes).to_hash
              hashed_relations << hashed
            end
          end
        end
      end
    end

    def root_key_for_item(serializable)
      serializable.class.name.split("::").last.underscore.to_sym
    end

    def root_key_for_relation(relation)
      serializable.klass.name.split("::").last.underscore.pluralize.to_sym
    end

    def serializer_class_for(model)
      "#{model.class.name.titleize}Serializer".constantize
    end

    def is_active_record_relation?(relation)
      #This is a pretty terrible way to test for this. find a better way
      serializable.respond_to? :klass
    end

    def root_key_for_collection
      self.class.name.split("::").last.underscore.gsub('_serializer', '').pluralize.to_sym
    end

    #----Module Inclusion

    def self.included(base)

      base.class_attribute :_attributes
      base.class_attribute :_relationships

      base._attributes = []
      base._relationships = { has_ones: [], has_manys: [] }

      base.extend(ClassMethods)

    end

    module ClassMethods
      def attributes(*args)
        self._attributes = args
      end

      def has_one(has_one)
        self._relationships[:has_ones] << has_one
      end

      def has_many(has_many)
        self._relationships[:has_manys] << has_many
      end
    end

  end
end


