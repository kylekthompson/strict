# frozen_string_literal: true

require "spec_helper"
require "strict/rspec"

RSpec.describe Strict::RSpec do
  describe "conform_to matcher" do
    let(:interface_class) do
      Class.new do
        include Strict::Interface

        expose(:call) do
          value String
          returns String
        end
      end
    end

    it "matches implementations that conform to the interface" do
      implementation = Class.new do
        def call(value:) = value
      end.new

      expect(implementation).to conform_to(interface_class)
      expect(Object.new).not_to conform_to(interface_class)
    end

    it "includes Strict's conformance details when the implementation does not conform" do
      expect do
        expect(Object.new).to conform_to(interface_class)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include("to conform to #{interface_class.inspect}")
        expect(error.message).to include("methods exposed in the interface were not defined")
        expect(error.message).to include("call")
      }
    end
  end

  describe "validate matcher" do
    it "matches when the validator accepts the value" do
      expect(String).to validate("value")
      expect(String).not_to validate(1)
    end

    it "describes a rejected value" do
      expect do
        expect(String).to validate(1)
      end.to raise_error(
        RSpec::Expectations::ExpectationNotMetError,
        "expected String to validate 1"
      )
    end

    it "describes an unexpectedly accepted value" do
      expect do
        expect(String).not_to validate("value")
      end.to raise_error(
        RSpec::Expectations::ExpectationNotMetError,
        'expected String not to validate "value"'
      )
    end
  end
end
