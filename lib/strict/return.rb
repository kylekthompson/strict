# frozen_string_literal: true

module Strict
  class Return
    class << self
      def make(validator = Validators::Anything.instance, **unsupported)
        raise ArgumentError, "Unsupported return options: #{unsupported.keys.join(', ')}" if unsupported.any?

        new(validator: validator)
      end
    end

    attr_reader :validator

    def initialize(validator:)
      @validator = validator
      @detailed_validator = DetailedValidator === validator
    end

    def valid?(value, configuration = Strict.configuration)
      violations(value, configuration).empty?
    end

    def violations(value, configuration = Strict.configuration)
      return Validation::NONE unless configuration.validate?
      return validator.violations(value) if @detailed_validator
      return Validation::NONE if validator === value

      Validation.invalid(validator, value)
    end
  end
end
