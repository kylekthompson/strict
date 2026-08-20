# frozen_string_literal: true

module Strict
  module Attributes
    module Class
      def coercer
        Coercer.new(self)
      end
    end
  end
end
