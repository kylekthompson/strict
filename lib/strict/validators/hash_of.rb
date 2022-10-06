# frozen_string_literal: true

module Strict
  module Validators
    class HashOf
      attr_reader :key_validator, :value_validator

      def initialize(key_validator, value_validator)
        @key_validator = key_validator
        @value_validator = value_validator
      end

      def ===(value)
        Hash === value && value.all? do |k, v|
          key_validator === k && value_validator === v
        end
      end

      def inspect
        "HashOf(#{key_validator.inspect} => #{value_validator.inspect})"
      end
      alias to_s inspect
    end
  end
end
