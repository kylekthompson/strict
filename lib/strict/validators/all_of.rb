# frozen_string_literal: true

module Strict
  module Validators
    class AllOf
      attr_reader :subvalidators

      def initialize(*subvalidators)
        @subvalidators = subvalidators
      end

      def ===(value)
        subvalidators.all? do |subvalidator|
          subvalidator === value
        end
      end
    end
  end
end
