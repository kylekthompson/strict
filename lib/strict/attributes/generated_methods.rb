# frozen_string_literal: true

module Strict
  module Attributes
    class GeneratedMethods < ::Module
      DECLARATION_MARKER = :@__strict_attributes_declared
      RESERVED_METHODS = %i[class eql? hash instance_variable_set public_send raise].freeze
      private_constant :DECLARATION_MARKER, :RESERVED_METHODS

      class << self
        def install_on(target, writable:)
          installation = ->(receiver, &definition) { install_attributes_on(receiver, writable, &definition) }
          target.define_singleton_method(:attributes) do |&definition|
            installation.call(self, &definition)
          end
        end

        private

        # rubocop:disable Metrics/MethodLength
        def install_attributes_on(target, writable, &definition)
          if target.instance_variable_defined?(DECLARATION_MARKER)
            raise ArgumentError, "Attributes are already declared for #{target}"
          end

          definition ||= -> {}
          inherited_attributes = target.respond_to?(:strict_attributes) ? target.strict_attributes.to_a : []
          configuration = Strict::Attributes::Dsl.run(attributes: inherited_attributes, &definition)
          declared_attributes = configuration.to_a - inherited_attributes
          generated_methods = new(
            configuration,
            writable: writable,
            target: target,
            declared_attributes: declared_attributes
          )
          target.instance_variable_set(DECLARATION_MARKER, true)
          target.include(Strict::Attributes::Instance, generated_methods)
          target.define_singleton_method(:strict_attributes) { configuration }
          target.extend(Strict::Attributes::Class)
        end
        # rubocop:enable Metrics/MethodLength
      end

      def initialize(configuration, writable:, target:, declared_attributes:)
        super()

        validate_collisions!(target, declared_attributes, writable: writable)
        configuration.each do |attribute|
          define_reader(attribute)
          define_writer(attribute) if writable
        end
      end

      private

      def validate_collisions!(target, attributes, writable:)
        attributes.each do |attribute|
          validate_method_available!(target, attribute.name, writable: writable)
          validate_method_available!(target, :"#{attribute.name}=", writable: writable) if writable
        end
      end

      def validate_method_available!(target, name, writable:)
        return unless method_reserved?(target, name, writable: writable)

        raise ArgumentError, "Generated attribute method #{name.inspect} already exists for #{target}"
      end

      def method_reserved?(target, name, writable:)
        method_defined_directly?(target, name) ||
          method_defined_directly?(Strict::Attributes::Instance, name) ||
          (!writable && method_defined_directly?(Strict::Value, name)) ||
          method_defined_directly?(BasicObject, name) ||
          RESERVED_METHODS.include?(name)
      end

      def method_defined_directly?(owner, name)
        owner.public_method_defined?(name, false) ||
          owner.protected_method_defined?(name, false) ||
          owner.private_method_defined?(name, false)
      end

      def define_reader(attribute)
        storage_name = attribute.instance_variable.to_s.delete_prefix("@").to_sym
        reader_module = ::Module.new { attr_reader(storage_name) }
        define_method(attribute.name, reader_module.instance_method(storage_name))
      end

      # rubocop:disable Metrics/MethodLength
      def define_writer(attribute)
        instance_variable = attribute.instance_variable
        define_method(:"#{attribute.name}=") do |value|
          assignable_class = self.class
          value = attribute.coerce(value, for_class: assignable_class)
          configuration = Strict.configuration
          violations = attribute.violations(value, configuration)

          if violations.empty?
            instance_variable_set(instance_variable, value)
          else
            raise Strict::AssignmentError.new(
              assignable_class: assignable_class,
              invalid_attribute: attribute,
              value: value,
              violations: Strict::Validation.prepend_path(violations, attribute.name)
            )
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
