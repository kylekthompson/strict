# frozen_string_literal: true

module Strict
  module Coercers
    class Hash
      attr_reader :key_coercer, :value_coercer

      def initialize(key_coercer = nil, value_coercer = nil)
        @key_coercer = key_coercer
        @value_coercer = value_coercer
      end

      def call(value)
        return value if value.nil? || !value.respond_to?(:to_h)

        if key_coercer && value_coercer
          coerce_keys_and_values(value.to_h)
        elsif key_coercer
          coerce_keys(value.to_h)
        elsif value_coercer
          coerce_values(value.to_h)
        else
          value.to_h
        end
      end

      private

      def coerce_keys_and_values(hash) = hash.to_h { |key, value| [key_coercer.call(key), value_coercer.call(value)] }
      def coerce_keys(hash) = hash.transform_keys { |key| key_coercer.call(key) }
      def coerce_values(hash) = hash.transform_values { |value| value_coercer.call(value) }
    end
  end
end
