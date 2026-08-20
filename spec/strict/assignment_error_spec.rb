# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::AssignmentError do
  describe ".new" do
    let(:assignable_class) { Class.new }

    it "builds a message with the invalid attribute" do
      error = described_class.new(
        assignable_class: assignable_class,
        invalid_attribute: Strict::Attribute.make(:attr_one, Strict::Validators::AnyOf.new(1, "2", nil)),
        value: 2
      )

      expected_message = <<~MESSAGE.chomp
        Assignment to attr_one of #{assignable_class} failed because:
          - got 2, expected AnyOf(1, "2", nil)
      MESSAGE

      expect(error.message).to eq(expected_message)
    end
  end
end
