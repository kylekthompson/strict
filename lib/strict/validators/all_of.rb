# frozen_string_literal: true

module Strict
  module Validators
    class AllOf
      include DetailedValidator

      attr_reader :subvalidators

      def initialize(*subvalidators)
        @subvalidators = subvalidators
      end

      def violations(value)
        violations = nil
        subvalidators.each do |subvalidator|
          subvalidator_violations = Validation.violations(subvalidator, value)
          next if subvalidator_violations.empty?

          violations ||= []
          violations.concat(subvalidator_violations)
        end
        violations || Validation::NONE
      end

      def inspect
        "AllOf(#{subvalidators.map(&:inspect).join(', ')})"
      end
      alias to_s inspect
    end
  end
end
