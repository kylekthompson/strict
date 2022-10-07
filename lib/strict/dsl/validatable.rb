# frozen_string_literal: true

module Strict
  module Dsl
    module Validatable
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
