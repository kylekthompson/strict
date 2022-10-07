# frozen_string_literal: true

module Strict
  module Methods
    class Configuration
      attr_reader :parameters, :returns

      def initialize(parameters:, returns:)
        @parameters = parameters
        @returns = returns
      end
    end
  end
end
