#Cooerce primitive values to more complex types such as dates etc.
#Coercion names map to 'types' defined in attribute definition
#and should be named "to_#{type}".
require 'date'

module Hat
  module Model
    module TypeCoercions

      def to_date_time(value)
        if value && value.kind_of?(String)
          DateTime.parse(value)
        elsif value.kind_of?(DateTime) || value.kind_of?(Date) || value.kind_of?(Time)
          value
        elsif value == nil
          nil
        else
          raise CoercionError, "Cannot coerce #{value.class.name} to DateTime"
        end
      end

    end

    class CoercionError < StandardError ; end
  end
end
