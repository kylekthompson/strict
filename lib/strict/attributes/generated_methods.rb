# frozen_string_literal: true

module Strict
  module Attributes
    class GeneratedMethods < ::Module
      def self.install_on(target, writable:)
        target.define_singleton_method(:attributes) do |&block|
          block ||= -> {}
          configuration = Strict::Attributes::Dsl.run(&block)
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
        define_method(attribute.name) do
          instance_variable_get(attribute.instance_variable)
        end
      end

      # rubocop:disable Metrics/MethodLength
      def define_writer(attribute)
        define_method(:"#{attribute.name}=") do |value|
          assignable_class = self.class
          value = attribute.coerce(value, for_class: assignable_class)
          configuration = Strict.configuration

          if attribute.valid?(value, configuration)
            instance_variable_set(attribute.instance_variable, value)
          else
            raise Strict::AssignmentError.new(
              assignable_class: assignable_class,
              invalid_attribute: attribute,
              value: value
            )
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
