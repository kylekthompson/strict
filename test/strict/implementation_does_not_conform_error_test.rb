# frozen_string_literal: true

require "test_helper"

module ImplementationDoesNotConformErrorTest
  # rubocop:disable Lint/EmptyClass
  class Interface
  end

  class Implementation
  end
  # rubocop:enable Lint/EmptyClass
end

describe Strict::ImplementationDoesNotConformError do
  describe ".new" do
    it "builds a message with only missing methods" do
      error = Strict::ImplementationDoesNotConformError.new(
        interface: ImplementationDoesNotConformErrorTest::Interface,
        receiver: ImplementationDoesNotConformErrorTest::Implementation,
        missing_methods: %i[first_method second_method],
        invalid_method_definitions: {}
      )

      expected_message = <<~MESSAGE.chomp
        ImplementationDoesNotConformErrorTest::Implementation's implementation of ImplementationDoesNotConformErrorTest::Interface does not conform:
          Some methods exposed in the interface were not defined in the implementation:
            - first_method
            - second_method
      MESSAGE

      assert_equal expected_message, error.message
    end

    it "builds a message with one invalid method definition" do
      error = Strict::ImplementationDoesNotConformError.new(
        interface: ImplementationDoesNotConformErrorTest::Interface,
        receiver: ImplementationDoesNotConformErrorTest::Implementation,
        missing_methods: nil,
        invalid_method_definitions: {
          first_method: { missing_parameters: %i[foo bar], additional_parameters: [], non_keyword_parameters: [] }
        }
      )

      expected_message = <<~MESSAGE.chomp
        ImplementationDoesNotConformErrorTest::Implementation's implementation of ImplementationDoesNotConformErrorTest::Interface does not conform:
          Some methods defined in the implementation did not conform to their interface:
            first_method:
              Some parameters were expected, but were not in the parameter list:
                - foo
                - bar
      MESSAGE

      assert_equal expected_message, error.message
    end

    it "builds a message with multiple invalid method definitions" do
      error = Strict::ImplementationDoesNotConformError.new(
        interface: ImplementationDoesNotConformErrorTest::Interface,
        receiver: ImplementationDoesNotConformErrorTest::Implementation,
        missing_methods: nil,
        invalid_method_definitions: {
          first_method: { missing_parameters: %i[foo bar], additional_parameters: [], non_keyword_parameters: [] },
          second_method: { missing_parameters: %i[fizz buzz], additional_parameters: [], non_keyword_parameters: [] }
        }
      )

      expected_message = <<~MESSAGE.chomp
        ImplementationDoesNotConformErrorTest::Implementation's implementation of ImplementationDoesNotConformErrorTest::Interface does not conform:
          Some methods defined in the implementation did not conform to their interface:
            first_method:
              Some parameters were expected, but were not in the parameter list:
                - foo
                - bar
            second_method:
              Some parameters were expected, but were not in the parameter list:
                - fizz
                - buzz
      MESSAGE

      assert_equal expected_message, error.message
    end

    it "builds a message with missing, additional, and non-keyword parameters" do
      error = Strict::ImplementationDoesNotConformError.new(
        interface: ImplementationDoesNotConformErrorTest::Interface,
        receiver: ImplementationDoesNotConformErrorTest::Implementation,
        missing_methods: nil,
        invalid_method_definitions: {
          first_method: {
            missing_parameters: %i[foo bar],
            additional_parameters: %i[fizz buzz],
            non_keyword_parameters: %i[bar bat]
          }
        }
      )

      expected_message = <<~MESSAGE.chomp
        ImplementationDoesNotConformErrorTest::Implementation's implementation of ImplementationDoesNotConformErrorTest::Interface does not conform:
          Some methods defined in the implementation did not conform to their interface:
            first_method:
              Some parameters were expected, but were not in the parameter list:
                - foo
                - bar
              Some parameters were not expected, but were in the parameter list:
                - fizz
                - buzz
              Some parameters were not keywords, but only keywords are supported:
                - bar
                - bat
      MESSAGE

      assert_equal expected_message, error.message
    end

    it "builds a message with missing methods and missing, additional, and non-keyword parameters for many methods" do
      error = Strict::ImplementationDoesNotConformError.new(
        interface: ImplementationDoesNotConformErrorTest::Interface,
        receiver: ImplementationDoesNotConformErrorTest::Implementation,
        missing_methods: %i[first_method second_method],
        invalid_method_definitions: {
          third_method: {
            missing_parameters: %i[a b],
            additional_parameters: %i[c d],
            non_keyword_parameters: %i[e f]
          },
          fourth_method: {
            missing_parameters: %i[g h],
            additional_parameters: %i[i j],
            non_keyword_parameters: %i[k l]
          }
        }
      )

      expected_message = <<~MESSAGE.chomp
        ImplementationDoesNotConformErrorTest::Implementation's implementation of ImplementationDoesNotConformErrorTest::Interface does not conform:
          Some methods exposed in the interface were not defined in the implementation:
            - first_method
            - second_method
          Some methods defined in the implementation did not conform to their interface:
            third_method:
              Some parameters were expected, but were not in the parameter list:
                - a
                - b
              Some parameters were not expected, but were in the parameter list:
                - c
                - d
              Some parameters were not keywords, but only keywords are supported:
                - e
                - f
            fourth_method:
              Some parameters were expected, but were not in the parameter list:
                - g
                - h
              Some parameters were not expected, but were in the parameter list:
                - i
                - j
              Some parameters were not keywords, but only keywords are supported:
                - k
                - l
      MESSAGE

      assert_equal expected_message, error.message
    end
  end
end
