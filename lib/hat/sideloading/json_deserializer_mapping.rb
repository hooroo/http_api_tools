require "active_support/core_ext/class/attribute"

module Hat
  module Sideloading
    module JsonDeserializerMapping

      #----Module Inclusion

      def self.included(base)
        base.class_attribute :_mappings
        base._mappings = {}
        base.extend(Dsl)
      end

      module Dsl
        def map(attr_name, target_class)
          self._mappings[attr_name] = target_class
        end

        def mappings
          self._mappings
        end
      end

    end
  end
end