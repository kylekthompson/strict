# frozen_string_literal: true

module Strict
  module Attributes
    class Recipe
      attr_reader :attributes

      def initialize(attributes:)
        @attributes = attributes
      end
    end
  end
end
