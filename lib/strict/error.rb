# frozen_string_literal: true

module Strict
  class Error < StandardError
    attr_reader :violations

    def initialize(message = nil, violations: Validation::NONE)
      @violations = violations.freeze
      super(message)
    end
  end
end
