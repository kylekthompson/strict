# frozen_string_literal: true

require "singleton"

module Strict
  module Validators
    class Anything
      include Singleton

      def ===(_value)
        true
      end
    end
  end
end
