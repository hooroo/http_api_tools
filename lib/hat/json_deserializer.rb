#Takes a json response based on the active-model-serializer relationship sideloading pattern
#and given a root object key, builds an object graph with cyclic relationships.
#See the id based pattern here - https://github.com/rails-api/active_model_serializers
#This currently works completely by use of conventions. Keys in the json map to class names.
#This could easily be extended to map keys to classes if we needed to break away from the convention
#based approach.
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
    end

    def deserialize

      if root_object = json[root_key]
        if root_object.kind_of? Array
          result = root_object.map {|json_item| create_from_json_item(target_class_for_key(root_key), json_item) }
        else
          result = create_from_json_item(target_class_for_key(root_key), root_object)
        end
      end

      result

    end

    private

    attr_accessor :json, :root_key, :sideload_map, :identity_map

    def create_from_json_item(target_class, json_item)

      return nil unless target_class

      existing_deserialized = identity_map.get(target_class, json_item['id'])

      return existing_deserialized if existing_deserialized

      relations = {}
      # delete_keys = []
      #we have to add this before we process subtree or we'll get circular issues

      target = target_class.new(json_item.with_indifferent_access)

      identity_map.put(target_class, json_item['id'], target)

      json_item.each do |key, value|

        sideload_key = sideload_key_for(key)

        if key.end_with? '_id'
          relations[sideload_key] = create_belongs_to(sideload_key, value)
          # delete_keys << key

        elsif key.end_with? '_ids'
          relations[sideload_key] = create_has_manys(sideload_key, value)
          # delete_keys << key
        end

      end

      # delete_keys.each { |key| json_item.delete(key) }
      relations.each {|key, related| target.send("#{key}=", related) unless related == nil }

      target

    end

    def create_belongs_to(sideload_key, id)
      if sideloaded_json = sideload_map.get(sideload_key, id)
        sideloaded_object = create_from_json_item(target_class_for_key(sideload_key), sideloaded_json)
      else
        nil
      end
    end

    def create_has_manys(sideload_key, ids)
      target_class = target_class_for_key(sideload_key)
      sideloaded_json_items = sideload_map.get_all(sideload_key, ids)

      sideloaded_json_items.map do |json_item|
        create_from_json_item(target_class, json_item)
      end
    end

    def sideload_key_for(attr_name)
      if attr_name.end_with? '_ids'
        attr_name.gsub('_ids', '').pluralize
      elsif attr_name.end_with? '_id'
        attr_name.gsub('_id', '')
      end
    end

    def target_class_for_key(key)
      key.to_s.singularize.camelize.constantize
    rescue NameError
      nil
    end


  end
end