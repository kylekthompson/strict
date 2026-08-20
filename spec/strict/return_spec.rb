# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Return do
  describe ".make" do
    it "has a default validator" do
      returns = described_class.make

      expect(returns.validator).to eq(Strict::Validators::Anything.instance)
    end

    it "accepts a validator" do
      returns = described_class.make(Strict::Validators::Boolean.instance)

      expect(returns.validator).to eq(Strict::Validators::Boolean.instance)
    end

    it "does not accept coercion" do
      expect do
        described_class.make(coerce: ->(value) { value + 1 })
      end.to raise_error(ArgumentError)
    end

    it "does not accept a value for 'default'" do
      expect do
        described_class.make(default: 1)
      end.to raise_error(ArgumentError)
    end

    it "does not accept a value for 'default_value'" do
      expect do
        described_class.make(default_value: 1)
      end.to raise_error(ArgumentError)
    end

    it "does not accept a value for 'default_generator'" do
      expect do
        described_class.make(default_generator: -> { 1 })
      end.to raise_error(ArgumentError)
    end
  end

  describe "#valid?" do
    it "uses the validator to check if the value is valid" do
      returns = described_class.make(Strict::Validators::Boolean.instance)

      expect(returns.valid?(true)).to be(true)
      expect(returns.valid?(false)).to be(true)
      expect(returns.valid?(nil)).to be(false)
      expect(returns.valid?(1)).to be(false)

      returns = described_class.make(Strict::Validators::AnyOf.new(Strict::Validators::Boolean.instance, nil))

      expect(returns.valid?(true)).to be(true)
      expect(returns.valid?(false)).to be(true)
      expect(returns.valid?(nil)).to be(true)
      expect(returns.valid?(1)).to be(false)
    end

    it "does not call the validator if sampling indicates not to" do
      validator = Class.new do
        attr_accessor :called

        def initialize
          @called = false
        end

        def ===(value)
          self.called = true
          Strict::Validators::Boolean.instance === value
        end
      end.new
      returns = described_class.make(validator)

      expect(validator.called).to be(false)
      Strict.with_overrides(sample_rate: 0) do
        expect(returns.valid?(true)).to be(true)
        expect(validator.called).to be(false)
        expect(returns.valid?(false)).to be(true)
        expect(validator.called).to be(false)
        expect(returns.valid?(nil)).to be(true)
        expect(validator.called).to be(false)
        expect(returns.valid?(1)).to be(true)
        expect(validator.called).to be(false)
      end

      Strict.with_overrides(sample_rate: 1) do
        expect(returns.valid?(nil)).to be(false)
        expect(validator.called).to be(true)
      end
    end
  end
end
