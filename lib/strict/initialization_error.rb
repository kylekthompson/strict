# frozen_string_literal: true

module Strict
  class InitializationError < Error
    attr_reader :remaining_attributes, :invalid_attributes, :missing_attributes

    def initialize(initializable_class:, remaining_attributes:, invalid_attributes:, missing_attributes:) # rubocop:disable Metrics/MethodLength
      super(
        message_from(
          initializable_class: initializable_class,
          remaining_attributes: remaining_attributes,
          invalid_attributes: invalid_attributes,
          missing_attributes: missing_attributes
        )
      )

      @remaining_attributes = remaining_attributes
      @invalid_attributes = invalid_attributes
      @missing_attributes = missing_attributes
    end

    private

    def message_from(initializable_class:, remaining_attributes:, invalid_attributes:, missing_attributes:)
      details = [
        invalid_attributes_message_from(invalid_attributes),
        missing_attributes_message_from(missing_attributes),
        remaining_attributes_message_from(remaining_attributes)
      ].compact.join("\n")

      "Initialization of #{initializable_class} failed because:\n#{details}"
    end

    def invalid_attributes_message_from(invalid_attributes)
      return nil unless invalid_attributes

      details = invalid_attributes.map do |attribute, value|
        "    - #{attribute.name}: got #{value.inspect}, expected #{attribute.validator.inspect}"
      end.join("\n")

      "  Some attributes were invalid:\n#{details}"
    end

    def missing_attributes_message_from(missing_attributes)
      return nil unless missing_attributes

      details = missing_attributes.map do |attribute_name|
        "    - #{attribute_name}"
      end.join("\n")

      "  Some attributes were missing:\n#{details}"
    end

    def remaining_attributes_message_from(remaining_attributes)
      return nil if remaining_attributes.none?

      details = remaining_attributes.map do |attribute_name|
        "    - #{attribute_name}"
      end.join("\n")

      "  Some attributes were provided, but not defined:\n#{details}"
    end
  end
end
