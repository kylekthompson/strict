# frozen_string_literal: true

module Strict
  module Interfaces
    module Instance
      attr_reader :implementation

      def initialize(implementation)
        self.class.verify_implementation!(implementation)

        @implementation = implementation
      end
    end
  end
end
