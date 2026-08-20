# frozen_string_literal: true

module Strict
  module Validators
    class ArrayOf
      include DetailedValidator

      attr_reader :element_validator

      def initialize(element_validator)
        @element_validator = element_validator
      end

      def coercer
        element_coercer = element_validator.coercer if element_validator.respond_to?(:coercer)
        Coercers::Array.new(element_coercer)
      end

      def violations(value)
        return Validation.invalid(self, value) unless Array === value

        violations = nil
        value.each_with_index do |element, index|
          element_violations = Validation.violations(element_validator, element)
          next if element_violations.empty?

          violations ||= []
          violations.concat(Validation.prepend_path(element_violations, index))
        end
        violations || Validation::NONE
      end

      def inspect
        "ArrayOf(#{element_validator.inspect})"
      end
      alias to_s inspect
    end
  end
end
