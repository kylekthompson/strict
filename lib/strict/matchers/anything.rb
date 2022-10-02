# frozen_string_literal: true

require "singleton"

module Strict
  module Matchers
    class Anything
      include Singleton

      def ===(_value)
        true
      end
    end
  end
end
