# frozen_string_literal: true

module Strict
  module Validators
    class AnyOf
      attr_reader :subvalidators

      def initialize(*subvalidators)
        @subvalidators = subvalidators
      end

      def ===(value)
        subvalidators.any? do |subvalidator|
          subvalidator === value
        end
      end

      def inspect
        "AnyOf(#{subvalidators.map(&:inspect).join(', ')})"
      end
      alias to_s inspect
    end
  end
end
