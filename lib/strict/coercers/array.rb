# frozen_string_literal: true

module Strict
  module Coercers
    class Array
      attr_reader :element_coercer

      def initialize(element_coercer = nil)
        @element_coercer = element_coercer
      end

      def call(value)
        return value if value.nil? || !value.respond_to?(:to_a)

        array = value.to_a
        return array unless element_coercer

        array.map { |element| element_coercer.call(element) }
      end
    end
  end
end
