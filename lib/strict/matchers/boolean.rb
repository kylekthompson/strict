# frozen_string_literal: true

require "singleton"

module Strict
  module Matchers
    class Boolean
      include Singleton

      def ===(value)
        value.equal?(true) || value.equal?(false)
      end
    end
  end
end
