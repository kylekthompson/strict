# frozen_string_literal: true

module Strict
  module Reader
    module ClassMethods
      def strict_attributes_recipe
        self::STRICT_INTERNAL_ATTRIBUTES_RECIPE__
      end
    end
  end
end
