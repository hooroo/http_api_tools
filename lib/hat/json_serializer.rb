require "active_support/core_ext/class/attribute"
require "active_support/json"
require 'active_support/core_ext/string/inflections'
require 'hat/relation_includes'
require 'hat/identity_map'

module Hat
  module JsonSerializer

    attr_reader :serializable, :relation_includes, :result, :attribute_mappings, :has_one_mappings, :has_many_mappings, :cached

    def initialize(serializable, options = {})
      @serializable = serializable
      @result = options[:result] || {}
      @relation_includes = options[:relation_includes] || RelationIncludes.new([])
      @identity_map = options[:identity_map] || IdentityMap.new
    end

    def to_json(*args)
      JSON.fast_generate(as_json)
    end

    def as_json(*args)
      if serializable.kind_of?(Array) || is_active_record_relation?(serializable)
        root_key = root_key_for_collection
        result[root_key] = []
        serializable.each do |serializable_item|
          serializer_class = serializer_class_for(serializable_item)
          hashed = { id: serializable_item.id }
          result[root_key] << hashed
          hashed.merge! serializer_class.new(serializable_item, result: result, identity_map: identity_map).includes(*relation_includes.includes).to_hash
        end
      else
        serialized_hash = to_hash
        root_key = root_key_for_item(serializable)
        result[root_key] = serialized_hash
      end

      add_sideload_data_from_identity_map
      add_metadata(root_key)

      result
    end

    def includes(*includes)
      self.relation_includes.include(includes)
      self
    end

    protected

    attr_accessor :identity_map

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

    def add_metadata(root_key)
      result[:meta] = {
        type: root_key.to_s.singularize,
        root_key: root_key
      }
    end

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

            type_key = attr_name.to_s

            unless identity_map.get(type_key, related.id)
              related = serializable.send("#{attr_name}")
              sideload_item(related, attr_name, type_key)
            end
          end
        end
      end
    end

    def sideload_has_manys

      has_manys.each do |attr_name|

        if relation_includes.include?(attr_name)

          has_many_relation = serializable.send("#{attr_name}") || []
          type_key = attr_name.to_s.singularize

          has_many_relation.each do |related|
            sideload_item(related, attr_name, type_key) unless identity_map.get(type_key, related.id)
          end
        end
      end
    end

    def sideload_item(related, attr_name, type_key)
      serializer_class = serializer_class_for(related)
      includes = relation_includes.nested_includes_for(attr_name) || []
      # placeholder = { id: related.id }
      # identity_map.put(type_key, related.id, placeholder) #prevent circular serialization
      hashed = serializer_class.new(related, result: result, identity_map: identity_map).includes(*includes).to_hash
      identity_map.put(type_key, related.id, hashed)
    end

    def add_sideload_data_from_identity_map
      start = Time.now
      identity_map.to_hash.each do |key, type_map|
        result[key.pluralize.to_sym] = type_map.values
      end
      puts "SIDELOAD DUMP: #{Time.now - start}"
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


