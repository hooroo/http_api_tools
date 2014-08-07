require_relative 'date_time_transformer'
require 'singleton'

module Hat
  module Model
    module Transformers
      class Registry

        include Singleton

        def from_raw(type, value)
          if transformer = get(type)
            transformer.from_raw(value)
          else
            value
          end
        end

        def to_raw(type, value)
          if transformer = get(type)
            transformer.to_raw(value)
          else
            value
          end
        end

        def get(type)
          registry[type.to_sym]
        end

        def register(type, transformer)
          if existing_transformer = get(type)
            raise "'#{type}' has already been registered as #{existing_transformer.name}"
          else
            registry[type.to_sym] = transformer
          end
        end

        private

        def registry
          @registry ||= {}
        end

      end

      class TransformError < StandardError ; end

      #Register Common Transformers
      Registry.instance.register(:date_time, Transformers::DateTimeTransformer)

    end
  end
end

