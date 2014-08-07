require 'date'

module Hat
  module Model
    module Transformers
      module DateTimeTransformer

        def self.from_raw(value)
          if value && value.kind_of?(String)
            ::DateTime.parse(value)
          elsif value.kind_of?(DateTime) || value.kind_of?(Date) || value.kind_of?(Time)
            value
          elsif value == nil
            nil
          else
            raise TransformError, "Cannot transform #{value.class.name} to DateTime"
          end
        end

        def self.to_raw(date_time)
          if date_time
            date_time.iso8601
          else
            nil
          end
        end

      end
    end
  end
end