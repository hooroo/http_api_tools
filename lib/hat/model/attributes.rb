# encoding: utf-8

require "active_support/core_ext/class/attribute"
require "hat/transformers/registry"

#Mix in to PORO to get basic attribute definition with type coercion and defaults.
#class MyClass
#  attribute :name
#  attribute :date, type: :date_time
#  attribute :tags, default: []
#
#NOTE: Be careful of adding default values other than primitives, arrays or basic hashes. Anything more
#Complex will need to be copied into each object rather than by direct reference - see the way
#arrays and hashes are handled in the 'default_for' method below.
module Hat
  module Model
    module Attributes

      def initialize(attrs = {})

        attrs = attrs.with_indifferent_access

        attributes.each do |attr_name, attr_options|
          raw_value = attrs[attr_name] || default_for(attr_options)
          set_raw_value(attr_name, raw_value, true) unless raw_value == nil
        end

        self.errors = attrs[:errors] || {}

      end

      # This method is not really satisfactory. It doesn't take into account relationships and
      # really only services a narrow use case. See - https://github.com/hooroo/hooroo-api-tools/issues/6
      def as_json(opts = {})
        json = {}

        attributes = self.attributes

        if opts[:exclude_read_only]
          attributes = attributes.reject {|_, options| options[:read_only]}
        end

        attributes.each do |attr_name, options|
          json[attr_name] = self.send(attr_name)
        end

        json.merge(errors: self.errors)
      end

      def attributes
        self.class._attributes
      end

      private

      def set_raw_value(attr_name, raw_value, apply_if_read_only = false)

        attr_def = attributes[attr_name]
        value = transformed_value(attr_def[:type], raw_value)

        if attr_def[:read_only] && apply_if_read_only
          instance_variable_set("@#{attr_name}", value)
        elsif
          self.send("#{attr_name}=", value)
        end
      end

      def transformed_value(type, raw_value)
        if type
          transformer_registry.from_raw(type, raw_value)
        else
          raw_value
        end
      end

      def transformer_registry
        Transformers::Registry.instance
      end

      #make sure we don't pass references to the same default object to each instance. Copy/dup where appropriate
      def default_for(options)
        assert_default_type_valid(options)
        default = options[:default]
        if default.kind_of? Array
          [].concat(default)
        elsif default.kind_of? Hash
          default.dup
        else
          default
        end
      end

      def assert_default_type_valid(options)
        if options[:default]
          default_class = options[:default].class
          unless [Array, Hash, Integer, Float, String].include? default_class
            raise "Default values of type #{default_class.name} are not supported."
          end
        end
      end

      #----Module Inclusion

      def self.included(base)
        base.class_attribute :_attributes
        base._attributes = {}
        base.extend(ClassMethods)
        base.send(:attr_accessor, :errors)
      end

      module ClassMethods

        def attribute(name, options = {})
          self._attributes[name] = options
          if options[:read_only]
            self.send(:attr_reader, name.to_sym)
          else
            self.send(:attr_accessor, name.to_sym)
          end
        end

      end

    end
  end
end