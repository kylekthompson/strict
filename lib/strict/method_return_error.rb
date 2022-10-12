# frozen_string_literal: true

module Strict
  class MethodReturnError < Error
    attr_reader :verifiable_method, :value

    def initialize(verifiable_method:, value:)
      super(message_from(verifiable_method:, value:))

      @verifiable_method = verifiable_method
      @value = value
    end

    private

    def message_from(verifiable_method:, value:)
      details = invalid_returns_message_from(verifiable_method, value)
      "#{verifiable_method}'s return value was invalid because:\n#{details}"
    end

    def invalid_returns_message_from(verifiable_method, value)
      "  - got #{value.inspect}, expected #{verifiable_method.returns.validator.inspect}"
    end
  end
end
