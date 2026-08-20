# frozen_string_literal: true

module Strict
  module Attributes
    class GeneratedMethods < ::Module
      def self.install_on(target, writable:)
        target.define_singleton_method(:attributes) do |&block|
          block ||= -> {}
          inherited_attributes = respond_to?(:strict_attributes) ? strict_attributes : []
          configuration = Strict::Attributes::Dsl.run(attributes: inherited_attributes, &block)
          include Strict::Attributes::GeneratedMethods.new(configuration, writable: writable)
          include Strict::Attributes::Instance
          extend Strict::Attributes::Class
        end
      end

      def initialize(configuration, writable:)
        super()

        const_set(Strict::Attributes::Class::CONSTANT, configuration)
        configuration.each do |attribute|
          define_reader(attribute)
          define_writer(attribute) if writable
        end
      end

      private

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
