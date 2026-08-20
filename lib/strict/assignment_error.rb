# frozen_string_literal: true

module Strict
  class AssignmentError < Error
    attr_reader :invalid_attribute, :value

    def initialize(assignable_class:, invalid_attribute:, value:, violations: Validation::NONE)
      super(
        message_from(assignable_class: assignable_class, invalid_attribute: invalid_attribute, value: value),
        violations: violations
      )

      @invalid_attribute = invalid_attribute
      @value = value
    end

    private

    def message_from(assignable_class:, invalid_attribute:, value:)
      details = invalid_attribute_message_from(invalid_attribute, value)
      "Assignment to #{invalid_attribute.name} of #{assignable_class} failed because:\n#{details}"
    end

    def invalid_attribute_message_from(invalid_attribute, value)
      "  - got #{value.inspect}, expected #{invalid_attribute.validator.inspect}"
    end
  end
end
