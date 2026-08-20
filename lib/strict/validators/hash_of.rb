# frozen_string_literal: true

module Strict
  module Validators
    class HashOf
      include DetailedValidator

      attr_reader :key_validator, :value_validator

      def initialize(key_validator, value_validator)
        @key_validator = key_validator
        @value_validator = value_validator
      end

      def coercer
        key_coercer = key_validator.coercer if key_validator.respond_to?(:coercer)
        value_coercer = value_validator.coercer if value_validator.respond_to?(:coercer)
        Coercers::Hash.new(key_coercer, value_coercer)
      end

      # rubocop:disable Metrics/MethodLength
      def violations(value)
        return Validation.invalid(self, value) unless Hash === value

        violations = nil
        value.each do |key, entry_value|
          key_violations = Validation.violations(key_validator, key)
          value_violations = Validation.violations(value_validator, entry_value)
          next if key_violations.empty? && value_violations.empty?

          violations ||= []
          violations.concat(Validation.prepend_path(key_violations, key))
          violations.concat(Validation.prepend_path(value_violations, key))
        end
        violations || Validation::NONE
      end
      # rubocop:enable Metrics/MethodLength

      def inspect
        "HashOf(#{key_validator.inspect} => #{value_validator.inspect})"
      end
      alias to_s inspect
    end
  end
end
