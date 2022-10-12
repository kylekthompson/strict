# frozen_string_literal: true

require "test_helper"

describe Strict::MethodCallError do
  describe ".new" do
    before do
      @verifiable_method = Strict::Methods::VerifiableMethod.new(
        method: Strict::Methods::VerifiableMethod.instance_method(:instance?),
        parameters: [],
        returns: [],
        instance: true
      )
    end

    it "builds a message with only remaining args" do
      error = Strict::MethodCallError.new(
        verifiable_method: @verifiable_method,
        remaining_args: [1, "2"],
        remaining_kwargs: {},
        invalid_parameters: nil,
        missing_parameters: nil
      )

      expected_message = <<~MESSAGE.chomp
        Calling Strict::Methods::VerifiableMethod#instance? failed because:
          Additional positional arguments were provided, but not defined:
            - 1
            - "2"
      MESSAGE

      assert_equal expected_message, error.message
    end

    it "builds a message with only remaining kwargs" do
      error = Strict::MethodCallError.new(
        verifiable_method: @verifiable_method,
        remaining_args: [],
        remaining_kwargs: { one: 1, two: "2" },
        invalid_parameters: nil,
        missing_parameters: nil
      )

      expected_message = <<~MESSAGE.chomp
        Calling Strict::Methods::VerifiableMethod#instance? failed because:
          Additional keyword arguments were provided, but not defined:
            - one: 1
            - two: "2"
      MESSAGE

      assert_equal expected_message, error.message
    end

    it "builds a message with only invalid parameters" do
      error = Strict::MethodCallError.new(
        verifiable_method: @verifiable_method,
        remaining_args: [],
        remaining_kwargs: {},
        invalid_parameters: {
          Strict::Parameter.make(:param_one, Strict::Validators::AnyOf.new(1, "2", nil)) => 2,
          Strict::Parameter.make(:param_two, nil) => 2
        },
        missing_parameters: nil
      )

      expected_message = <<~MESSAGE.chomp
        Calling Strict::Methods::VerifiableMethod#instance? failed because:
          Some arguments were invalid:
            - param_one: got 2, expected AnyOf(1, "2", nil)
            - param_two: got 2, expected nil
      MESSAGE

      assert_equal expected_message, error.message
    end

    it "builds a message with only missing parameters" do
      error = Strict::MethodCallError.new(
        verifiable_method: @verifiable_method,
        remaining_args: [],
        remaining_kwargs: {},
        invalid_parameters: nil,
        missing_parameters: %i[param_one param_two]
      )

      expected_message = <<~MESSAGE.chomp
        Calling Strict::Methods::VerifiableMethod#instance? failed because:
          Some arguments were missing:
            - param_one
            - param_two
      MESSAGE

      assert_equal expected_message, error.message
    end

    it "builds a message with all kinds of problems" do
      error = Strict::MethodCallError.new(
        verifiable_method: @verifiable_method,
        remaining_args: [1, "2"],
        remaining_kwargs: { three: 3, four: "4" },
        invalid_parameters: {
          Strict::Parameter.make(:five, Strict::Validators::AnyOf.new(1, "2", nil)) => 2,
          Strict::Parameter.make(:six, nil) => 2
        },
        missing_parameters: %i[seven eight]
      )

      expected_message = <<~MESSAGE.chomp
        Calling Strict::Methods::VerifiableMethod#instance? failed because:
          Some arguments were invalid:
            - five: got 2, expected AnyOf(1, "2", nil)
            - six: got 2, expected nil
          Some arguments were missing:
            - seven
            - eight
          Additional positional arguments were provided, but not defined:
            - 1
            - "2"
          Additional keyword arguments were provided, but not defined:
            - three: 3
            - four: "4"
      MESSAGE

      assert_equal expected_message, error.message
    end
  end
end
