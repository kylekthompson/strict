# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::InitializationError do
  describe ".new" do
    let(:initializable_class) { Class.new }

    it "builds a message with only invalid attributes" do
      error = described_class.new(
        initializable_class: initializable_class,
        remaining_attributes: [],
        invalid_attributes: {
          Strict::Attribute.make(:attr_one, Strict::Validators::AnyOf.new(1, "2", nil)) => 2,
          Strict::Attribute.make(:attr_two, nil) => 2
        },
        missing_attributes: nil
      )

      expected_message = <<~MESSAGE.chomp
        Initialization of #{initializable_class} failed because:
          Some attributes were invalid:
            - attr_one: got 2, expected AnyOf(1, "2", nil)
            - attr_two: got 2, expected nil
      MESSAGE

      expect(error.message).to eq(expected_message)
    end

    it "builds a message with only missing attributes" do
      error = described_class.new(
        initializable_class: initializable_class,
        remaining_attributes: [],
        invalid_attributes: nil,
        missing_attributes: %i[attr_three attr_four]
      )

      expected_message = <<~MESSAGE.chomp
        Initialization of #{initializable_class} failed because:
          Some attributes were missing:
            - attr_three
            - attr_four
      MESSAGE

      expect(error.message).to eq(expected_message)
    end

    it "builds a message with only remaining attributes" do
      error = described_class.new(
        initializable_class: initializable_class,
        remaining_attributes: %i[attr_five attr_six],
        invalid_attributes: nil,
        missing_attributes: nil
      )

      expected_message = <<~MESSAGE.chomp
        Initialization of #{initializable_class} failed because:
          Some attributes were provided, but not defined:
            - attr_five
            - attr_six
      MESSAGE

      expect(error.message).to eq(expected_message)
    end

    it "builds a message with all kinds of attributes" do
      error = described_class.new(
        initializable_class: initializable_class,
        remaining_attributes: %i[attr_five attr_six],
        invalid_attributes: {
          Strict::Attribute.make(:attr_one, Strict::Validators::AnyOf.new(1, "2", nil)) => 2,
          Strict::Attribute.make(:attr_two, nil) => 2
        },
        missing_attributes: %i[attr_three attr_four]
      )

      expected_message = <<~MESSAGE.chomp
        Initialization of #{initializable_class} failed because:
          Some attributes were invalid:
            - attr_one: got 2, expected AnyOf(1, "2", nil)
            - attr_two: got 2, expected nil
          Some attributes were missing:
            - attr_three
            - attr_four
          Some attributes were provided, but not defined:
            - attr_five
            - attr_six
      MESSAGE

      expect(error.message).to eq(expected_message)
    end
  end
end
