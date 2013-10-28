require 'active_support/core_ext/hash/indifferent_access'

module Hat
  class IdentityMap

    def initialize
      @identity_map = Hash.new.with_indifferent_access
    end

    def get(type, id)
      if id_map = identity_map[type]
        id_map[id]
      end
    end

    def put(type, id, object)
      unless identity_map[type]
        identity_map[type] = {}
      end
      identity_map[type][id] = object
      self
    end

    def inspect
      identity_map.inspect
    end

    private

    attr_accessor :identity_map

  end
end