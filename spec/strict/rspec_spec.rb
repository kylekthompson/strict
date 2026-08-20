# frozen_string_literal: true

require "open3"
require "spec_helper"
require "strict/rspec"

RSpec.describe Strict::RSpec do
  describe "public surface" do
    it "keeps the core require independent from RSpec" do
      lib = File.expand_path("../../lib", __dir__)
      script = 'require "strict"; abort "RSpec loaded" if defined?(RSpec)'

      output, status = Open3.capture2e(RbConfig.ruby, "-I#{lib}", "-e", script)

      expect(output).to be_empty
      expect(status).to be_success
    end

    it "exposes the helper through RSpec without exposing adapter internals" do
      expect(self).to respond_to(:strict_double)
      expect(described_class.constants(false)).to be_empty
      expect(described_class.singleton_methods(false)).to be_empty
    end
  end

  describe "composable Strict values" do
    it "supports nested RSpec matchers in received arguments" do
      nested_value_class = Struct.new(:a)
      nested_validator = nested_value_class
      value_class = Class.new do
        include Strict::Value

        attributes do
          other_value nested_validator
          other_values ArrayOf(nested_validator)
        end
      end
      receiver_class = Class.new do
        def bar(value:); end
      end
      receiver = instance_spy(receiver_class)
      receiver.bar(
        value: value_class.new(
          other_value: nested_value_class.new(1),
          other_values: [nested_value_class.new(2)]
        )
      )

      expect(receiver).to have_received(:bar).with(
        value: value_class.new(
          other_value: have_attributes(a: 1),
          other_values: [have_attributes(a: 2)]
        )
      )
      expect(receiver).not_to have_received(:bar).with(
        value: value_class.new(
          other_value: have_attributes(a: 2),
          other_values: [have_attributes(a: 3)]
        )
      )
    end
  end

  describe "strict_double" do
    it "builds a conforming interface implementation double" do
      interface_class = Class.new do
        include Strict::Interface

        expose(:call) do
          value String
          returns String
        end

        expose(:reset) { returns nil }
      end

      implementation = strict_double(interface_class, call: "result")

      expect(implementation).to conform_to(interface_class)
      expect(interface_class.new(implementation).call(value: "input")).to eq("result")
      expect(implementation.reset).to be_nil
    end

    it "rejects stubs for methods outside the interface" do
      interface_class = Class.new do
        include Strict::Interface

        expose(:call) { returns String }
      end

      expect do
        strict_double(interface_class, unknown: true)
      end.to raise_error(RSpec::Mocks::MockExpectationError)
    end

    it "builds a verifying double for a Strict value" do
      value_class = Class.new do
        include Strict::Value

        attributes do
          name String
        end
      end

      value = strict_double(value_class, name: "test value")

      expect(value.name).to eq("test value")
      expect do
        strict_double(value_class, unknown: true)
      end.to raise_error(RSpec::Mocks::MockExpectationError)
    end
  end

  describe "Strict validation of verifying doubles" do
    let(:value_class) do
      Class.new do
        include Strict::Value

        attributes do
          name String
        end
      end
    end

    let(:container_class) do
      value_validator = value_class

      Class.new do
        include Strict::Value

        attributes do
          value value_validator
        end
      end
    end

    it "accepts an instance double as a class-validated attribute" do
      value = instance_double(value_class, name: "test value")

      container = container_class.new(value: value)

      expect(container.value).to be(value)
      expect(value_class).to validate(value)
    end

    it "accepts instance doubles as signed parameters and return values" do
      value_validator = value_class
      callable_class = Class.new do
        include Strict::Method

        sig do
          value value_validator
          returns value_validator
        end
        def call(value) = value
      end
      value = instance_double(value_class)

      expect(callable_class.new.call(value)).to be(value)
    end

    it "continues to reject plain doubles" do
      value = double("value") # rubocop:disable RSpec/VerifiedDoubles

      expect do
        container_class.new(value: value)
      end.to raise_error(Strict::InitializationError) { |error|
        expect(error.violations).to eq(
          [Strict::Violation.new(path: [:value], code: :invalid, value: value, validator: value_class)]
        )
      }
      expect(value_class).not_to validate(value)
    end
  end

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
        "expected String to validate 1\n\nviolations:\n  - at root: expected String, got 1"
      )
    end

    it "describes detailed violation paths" do
      validator = Class.new do
        include Strict::DetailedValidator

        def violations(value)
          return [] if Integer === value.a

          [Strict::Violation.new(path: [:a], code: :invalid, value: value.a, validator: Integer)]
        end
      end.new
      value = Struct.new(:a).new("1")

      expect do
        expect(validator).to validate(value)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError) { |error|
        expect(error.message).to include('at [:a]: expected Integer, got "1"')
      }
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
