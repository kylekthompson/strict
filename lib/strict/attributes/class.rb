# frozen_string_literal: true

module Strict
  module Attributes
    module Class
      CONSTANT = :STRICT_INTERNAL_ATTRIBUTES_CONFIGURATION__

      def strict_attributes
        self::STRICT_INTERNAL_ATTRIBUTES_CONFIGURATION__
      end

      def coercer
        Coercer.new(self)
      end
    end
  end
end
