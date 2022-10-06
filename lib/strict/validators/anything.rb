# frozen_string_literal: true

require "singleton"

module Strict
  module Validators
    class Anything
      include Singleton

      def ===(_value)
        true
      end

      def inspect
        "Anything()"
      end
      alias to_s inspect
    end
  end
end
