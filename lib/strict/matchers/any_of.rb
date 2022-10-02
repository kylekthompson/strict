# frozen_string_literal: true

module Strict
  module Matchers
    class AnyOf
      attr_reader :submatchers

      def initialize(*submatchers)
        @submatchers = submatchers
      end

      def ===(value)
        submatchers.any? do |submatcher|
          submatcher === value
        end
      end
    end
  end
end
