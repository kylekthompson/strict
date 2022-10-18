# frozen_string_literal: true

module Strict
  module Interfaces
    class Coercer
      attr_reader :interface_class

      def initialize(interface_class)
        @interface_class = interface_class
      end

      def call(value)
        return value if value.nil? || value.instance_of?(interface_class)

        interface_class.new(value)
      end
    end
  end
end
