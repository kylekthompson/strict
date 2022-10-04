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
    end
  end
end
