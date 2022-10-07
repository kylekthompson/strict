# frozen_string_literal: true

module Strict
  class Return
    class << self
      def make(validator = Validators::Anything.instance, coerce: false)
        new(validator:, coercer: coerce)
      end
    end

    attr_reader :validator, :coercer

    def initialize(validator:, coercer:)
      @validator = validator
      @coercer = coercer
    end

    def valid?(value)
      validator === value
    end

    def coerce(value)
      return value unless coercer

      coercer.call(value)
    end
  end
end
