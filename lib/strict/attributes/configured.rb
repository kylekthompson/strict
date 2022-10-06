# frozen_string_literal: true

module Strict
  module Attributes
    module Configured
      CONSTANT = :STRICT_INTERNAL_ATTRIBUTES_CONFIGURATION__

      def strict_attributes
        self::STRICT_INTERNAL_ATTRIBUTES_CONFIGURATION__
      end
    end
  end
end
