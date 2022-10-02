# frozen_string_literal: true

module Strict
  module Matchers
    class ArrayOf
      attr_reader :element_matcher

      def initialize(element_matcher)
        @element_matcher = element_matcher
      end

      def ===(value)
        Array === value && value.all? do |v|
          element_matcher === v
        end
      end
    end
  end
end
