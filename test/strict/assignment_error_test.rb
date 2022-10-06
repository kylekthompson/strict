# frozen_string_literal: true

require "test_helper"

describe Strict::AssignmentError do
  describe ".new" do
    before do
      @assignable_class = Class.new
    end

    it "builds a message with the invalid attribute" do
      error = Strict::AssignmentError.new(
        assignable_class: @assignable_class,
        invalid_attribute: Strict::Attribute.make(:attr_one, Strict::Validators::AnyOf.new(1, "2", nil)),
        value: 2
      )

      expected_message = <<~MESSAGE.chomp
        Assignment to attr_one of #{@assignable_class} failed because:
          - got 2, expected AnyOf(1, "2", nil)
      MESSAGE

      assert_equal expected_message, error.message
    end
  end
end
