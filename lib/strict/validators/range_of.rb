# frozen_string_literal: true

module Strict
  module Validators
    class RangeOf
      attr_reader :element_validator

      def initialize(element_validator)
        @element_validator = element_validator
      end

      def ===(value)
        Range === value && [value.begin, value.end].compact.all? do |v|
          element_validator === v
        end
      end

      def inspect
        "RangeOf(#{element_validator.inspect})"
      end
      alias to_s inspect
    end
  end
end
