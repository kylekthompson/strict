# frozen_string_literal: true

module Strict
  module Matchers
    class AllOf
      attr_reader :submatchers

      def initialize(*submatchers)
        @submatchers = submatchers
      end

      def ===(value)
        submatchers.all? do |submatcher|
          submatcher === value
        end
      end
    end
  end
end
