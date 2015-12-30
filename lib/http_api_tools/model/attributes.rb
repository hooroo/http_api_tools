# encoding: utf-8

require "active_support/core_ext/class/attribute"
require 'active_support/core_ext/string/inflections'
require_relative "transformers/registry"
require_relative "has_many_array"

#Mix in to PORO to get basic attribute definition with type coercion and defaults.
#class MyClass
#  attribute :name
#  attribute :date, type: :date_time
#  attribute :tags, default: []
#
#NOTE: Be careful of adding default values other than primitives, arrays or basic hashes. Anything more
#Complex will need to be copied into each object rather than by direct reference - see the way
#arrays and hashes are handled in the 'default_for' method below.
module HttpApiTools
  module Model
    module Attributes

      def initialize(attrs = {})

        attrs = attrs.with_indifferent_access if self._with_indifferent_access

        attributes.each do |attr_name, attr_options|
          value = attrs[attr_name]
          value = attrs[attr_name.to_s.freeze] if value.nil? && !self._with_indifferent_access

          raw_value = value == nil ? default_for(attr_options) : value
          set_raw_value(attr_name, attr_options, raw_value, true) unless raw_value == nil
        end

        self.errors = attrs[:errors] || {}

      end

      def attributes
        self.class._attributes
      end

      def has_many_changed(has_many_name)
        send("#{has_many_name.to_s.singularize}_ids=".freeze, Array(send(has_many_name)).map(&:id).compact)
      end

      private

      def set_raw_value(attr_name, attr_def, raw_value, apply_if_read_only = false)

        value = transformed_value(attr_def[:type], raw_value)

        if attr_def[:read_only] && apply_if_read_only
          instance_variable_set("@#{attr_name}".freeze, value)
        elsif
          self.send("#{attr_name}=".freeze, value)
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

      def set_belongs_to_value(attr_name, value)
        instance_variable_set("@#{attr_name}".freeze, value)
        send("#{attr_name}_id=".freeze, value.try(:id))
      end

      def set_has_many_value(attr_name, value)
        instance_variable_set("@#{attr_name}".freeze, HasManyArray.new(value, self, attr_name))
        has_many_changed(attr_name)
      end

      #----Module Inclusion

      def self.included(base)
        base.class_attribute :_attributes
        base._attributes = {}

        base.class_attribute :_has_many_relations
        base._has_many_relations = {}

        base.class_attribute :_belongs_to_relations
        base._belongs_to_relations = {}

        base.extend(ClassMethods)
        base.send(:attr_accessor, :errors)

        base.class_attribute :_with_indifferent_access
        base._with_indifferent_access = false
      end

      module ClassMethods

        def attributes
          self._attributes
        end

        def belongs_to_relations
          self._belongs_to_relations
        end

        def has_many_relations
          self._has_many_relations
        end

        def attribute(attr_name, options = {})
          self._attributes[attr_name] = options
          if options[:read_only]
            self.send(:attr_reader, attr_name.to_sym)
          else
            self.send(:attr_accessor, attr_name.to_sym)
          end
        end

        def belongs_to(attr_name, options = {})

          self._belongs_to_relations[attr_name] = options

          id_attr_name = "#{attr_name}_id"
          id_setter_method_name = "#{id_attr_name}="

          send(:attr_reader, attr_name)
          send(:attr_reader, id_attr_name)

          define_method("#{attr_name}=") do |value|
            set_belongs_to_value(attr_name, value)
          end

          define_method(id_setter_method_name) do |value|
            instance_variable_set("@#{id_attr_name}", value)
          end
        end

        def has_many(attr_name, options = {})

          self._has_many_relations[attr_name] = options

          ids_attr_name = "#{attr_name.to_s.singularize}_ids"
          id_setter_method_name = "#{ids_attr_name}="

          send(:attr_reader, attr_name)
          send(:attr_reader, ids_attr_name)

          define_method("#{attr_name}=") do |value|
            set_has_many_value(attr_name, value)
          end

          define_method(id_setter_method_name) do |value|
            instance_variable_set("@#{ids_attr_name}", value)
          end

        end

        def with_indifferent_access(value)
          self._with_indifferent_access = value
        end

      end
    end
  end
end
