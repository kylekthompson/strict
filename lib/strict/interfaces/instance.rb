# frozen_string_literal: true

module Strict
  module Interfaces
    module Instance
      attr_reader :implementation

      def initialize(implementation)
        self.class.strict_interface_conformance.verify!(implementation)

        @implementation = implementation
      end
    end
  end
end
