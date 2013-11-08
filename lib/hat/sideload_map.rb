require 'active_support/core_ext/string/inflections'
require 'hat/identity_map'
#Holds a fast access map of all sideloaded json for deserialization

module Hat

  class SideloadMap

    def initialize(json, root_key)
      super()
      @root_key = root_key
      @identity_map = IdentityMap.new

      build_from_json(json)
    end

    def get(type, id)
      identity_map.get(type.singularize, id)
    end

    def get_all(type, ids)
      ids.map { |id| get(type, id)}.compact
    end

    def inspect
      identity_map.inspect
    end

    private

    attr_accessor :root_key, :identity_map


    def put(type, id, object)
      identity_map.put(type.singularize, id, object)
    end

    def build_from_json(json)

      json[root_key].each do |json_item|
        put(root_key, json_item['id'], json_item)
      end

      if json['linked']
        json['linked'].each do |type_key, sideloaded_json_item|
          sideloaded_json_item.each { |json_item| put(type_key, json_item['id'], json_item) }
        end
      end

    end

  end
end