# frozen_string_literal: true

module Strict
  module Validators
    class ArrayOf
      attr_reader :element_validator

      def initialize(element_validator)
        @element_validator = element_validator
      end

      def ===(value)
        Array === value && value.all? do |v|
          element_validator === v
        end
      end

      def inspect
        "ArrayOf(#{element_validator.inspect})"
      end
      alias to_s inspect
    end
  end
end
