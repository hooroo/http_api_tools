#type/id map for mapping string or symbol keys and ids to objects.
#Optimised for speed... (don't rewrite this to use hash with indifferent access as it is slower)
module Hat
  class IdentityMap

    def initialize
      @identity_map = {}
    end

    def get(type, id)
      if id_map = identity_map[type.to_sym]
        id_map[id]
      end
    end

    def put(type, id, object)
      type_symbol = type.to_sym
      unless identity_map[type_symbol]
        identity_map[type_symbol] = {}
      end
      identity_map[type_symbol][id] = object
      self
    end

    def to_hash
      @identity_map
    end

    def inspect
      identity_map.inspect
    end

    private

    attr_accessor :identity_map

  end
end