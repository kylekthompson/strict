# frozen_string_literal: true

require "test_helper"

describe Strict::InitializationError do
  describe ".new" do
    before do
      @initializable_class = Class.new
    end

    it "builds a message with only invalid attributes" do
      error = Strict::InitializationError.new(
        initializable_class: @initializable_class,
        remaining_attributes: [],
        invalid_attributes: {
          Strict::Attribute.make(:attr_one, Strict::Validators::AnyOf.new(1, "2", nil)) => 2,
          Strict::Attribute.make(:attr_two, nil) => 2
        },
        missing_attributes: nil
      )

      expected_message = <<~MESSAGE.chomp
        Initialization of #{@initializable_class} failed because:
          Some attributes were invalid:
            - 'attr_one': got 2, expected AnyOf(1, "2", nil)
            - 'attr_two': got 2, expected nil
      MESSAGE

      assert_equal expected_message, error.message
    end

    it "builds a message with only missing attributes" do
      error = Strict::InitializationError.new(
        initializable_class: @initializable_class,
        remaining_attributes: [],
        invalid_attributes: nil,
        missing_attributes: %i[attr_three attr_four]
      )

      expected_message = <<~MESSAGE.chomp
        Initialization of #{@initializable_class} failed because:
          Some attributes were missing:
            - 'attr_three'
            - 'attr_four'
      MESSAGE

      assert_equal expected_message, error.message
    end

    it "builds a message with only remaining attributes" do
      error = Strict::InitializationError.new(
        initializable_class: @initializable_class,
        remaining_attributes: %i[attr_five attr_six],
        invalid_attributes: nil,
        missing_attributes: nil
      )

      expected_message = <<~MESSAGE.chomp
        Initialization of #{@initializable_class} failed because:
          Some attributes were provided, but not defined:
            - 'attr_five'
            - 'attr_six'
      MESSAGE

      assert_equal expected_message, error.message
    end

    it "builds a message with all kinds of attributes" do
      error = Strict::InitializationError.new(
        initializable_class: @initializable_class,
        remaining_attributes: %i[attr_five attr_six],
        invalid_attributes: {
          Strict::Attribute.make(:attr_one, Strict::Validators::AnyOf.new(1, "2", nil)) => 2,
          Strict::Attribute.make(:attr_two, nil) => 2
        },
        missing_attributes: %i[attr_three attr_four]
      )

      expected_message = <<~MESSAGE.chomp
        Initialization of #{@initializable_class} failed because:
          Some attributes were invalid:
            - 'attr_one': got 2, expected AnyOf(1, "2", nil)
            - 'attr_two': got 2, expected nil
          Some attributes were missing:
            - 'attr_three'
            - 'attr_four'
          Some attributes were provided, but not defined:
            - 'attr_five'
            - 'attr_six'
      MESSAGE

      assert_equal expected_message, error.message
    end
  end
end
