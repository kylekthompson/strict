# frozen_string_literal: true

require "singleton"

module Strict
  module Validators
    class Boolean
      include Singleton

      def ===(value)
        value.equal?(true) || value.equal?(false)
      end

      def inspect
        "Boolean()"
      end
      alias to_s inspect
    end
  end
end
