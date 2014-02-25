# encoding: utf-8

#Takes a json response based on the active-model-serializer relationship sideloading pattern
#and given a root object key, builds an object graph with cyclic relationships.
#See the id based pattern here - https://github.com/rails-api/active_model_serializers
require 'active_support/core_ext/hash/indifferent_access'
require 'hat/sideload_map'
require 'hat/identity_map'

module Hat
  class JsonDeserializer

    def initialize(json)
      @json = json
      @root_key = json['meta']['root_key'].to_s
      @identity_map = IdentityMap.new
      @sideload_map = SideloadMap.new(json, root_key)
      @key_to_class_mappings = {}
    end

    def deserialize
      json[root_key].map {|json_item| create_from_json_item(target_class_for_key(root_key), json_item) }
    end

    private

    attr_accessor :json, :root_key, :sideload_map, :identity_map, :key_to_class_mappings

    def create_from_json_item(target_class, json_item)

      return nil unless target_class

      existing_deserialized = identity_map.get(target_class.name, json_item['id'])

      return existing_deserialized if existing_deserialized

      relations = {}

      #we have to add this before we process subtree or we'll get circular issues
      target = target_class.new(json_item.merge(:set_read_only => true).with_indifferent_access)
      target_class_name = target_class.name

      identity_map.put(target_class_name, json_item['id'], target)

      links = json_item['links'] || {}

      links.each do |relation_name, value|

        if value.kind_of? Array
          related = create_has_manys(target_class_name, relation_name, value)
        else
          related = create_belongs_to(target_class_name, relation_name, value)
        end

        target.send("#{relation_name}=", related)

      end

      target

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
        return attribute_mapping.name.underscore
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
      key.to_s.singularize.camelize.constantize
    rescue NameError
      nil
    end


  end
end