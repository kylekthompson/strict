# frozen_string_literal: true

module Strict
  module Attributes
    class Dsl < BasicObject
      class << self
        def run(&)
          dsl = new
          dsl.instance_eval(&)
          ::Strict::Attributes::Configuration.new(attributes: dsl.__strict_dsl_internal_attributes)
        end
      end

      attr_reader :__strict_dsl_internal_attributes

      def initialize
        @__strict_dsl_internal_attributes = []
      end

      def strict_attribute(*args, **kwargs)
        __strict_dsl_internal_attributes << ::Strict::Attribute.make(*args, **kwargs)
        nil
      end

      def method_missing(name, *args, **kwargs)
        if respond_to_missing?(name)
          strict_attribute(name, *args, **kwargs)
        else
          super
        end
      end

      def respond_to_missing?(method_name, _include_private = nil)
        first_letter = method_name.to_s.each_char.first
        first_letter.eql?(first_letter.downcase)
      end

      ## Validators
      # rubocop:disable Naming/MethodName

      def AllOf(*subvalidators) = ::Strict::Validators::AllOf.new(*subvalidators)
      def AnyOf(*subvalidators) = ::Strict::Validators::AnyOf.new(*subvalidators)
      def Anything = ::Strict::Validators::Anything.instance
      def ArrayOf(element_validator) = ::Strict::Validators::ArrayOf.new(element_validator)
      def Boolean = ::Strict::Validators::Boolean.instance

      def HashOf(key_validator_to_value_validator)
        if key_validator_to_value_validator.size != 1
          raise ArgumentError, "HashOf's usage is: HashOf(KeyValidator => ValueValidator)"
        end

        key_validator, value_validator = key_validator_to_value_validator.first
        ::Strict::Validators::HashOf.new(key_validator, value_validator)
      end

      def RangeOf(element_validator) = ::Strict::Validators::RangeOf.new(element_validator)

      # rubocop:enable Naming/MethodName
    end
  end
end
