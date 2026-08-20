# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Parameter do
  describe ".make" do
    it "has defaults when only given a name" do
      parameter = described_class.make("attr_name")

      expect(parameter.name).to eq(:attr_name)
      expect(parameter.validator).to eq(Strict::Validators::Anything.instance)
      expect(parameter.default_generator).to eq(Strict::Parameter::NOT_PROVIDED)
      expect(parameter.coercer).to be_falsey
      expect(parameter.optional?).to be(false)
    end

    it "accepts a combination of all arguments" do
      parameter = described_class.make(
        :attr_name,
        Strict::Validators::Boolean.instance,
        coerce: ->(value) { value + 1 },
        default: 1
      )

      expect(parameter.name).to eq(:attr_name)
      expect(parameter.validator).to eq(Strict::Validators::Boolean.instance)
      expect(parameter.default_generator).not_to eq(Strict::Parameter::NOT_PROVIDED)
      expect(parameter.default_generator.call).to eq(1)
      expect(parameter.coercer).to be_truthy
      expect(parameter.optional?).to be(true)
    end

    it "accepts a validator" do
      parameter = described_class.make(:attr_name, Strict::Validators::Boolean.instance)

      expect(parameter.validator).to eq(Strict::Validators::Boolean.instance)
    end

    it "accepts a coerce value" do
      parameter = described_class.make(:attr_name, coerce: ->(value) { value + 1 })

      expect(parameter.coercer).to be_truthy
    end

    it "uses the validator's coercer by default" do
      coercer = ->(value) { value.to_s }
      validator = Object.new
      validator.define_singleton_method(:coercer) { coercer }

      parameter = described_class.make(:attr_name, validator)

      expect(parameter.coercer).to be(coercer)
    end

    it "accepts a value for 'default'" do
      parameter = described_class.make(:attr_name, default: 1)

      expect(parameter.default_generator).not_to eq(Strict::Parameter::NOT_PROVIDED)
      expect(parameter.default_generator.call).to eq(1)
      expect(parameter.optional?).to be(true)
    end

    it "accepts a callable for 'default'" do
      parameter = described_class.make(:attr_name, default: -> { 1 })

      expect(parameter.default_generator).not_to eq(Strict::Parameter::NOT_PROVIDED)
      expect(parameter.default_generator.call).to eq(1)
      expect(parameter.optional?).to be(true)
    end

    it "accepts a value for 'default_value'" do
      parameter = described_class.make(:attr_name, default_value: -> { 1 })

      expect(parameter.default_generator).not_to eq(Strict::Parameter::NOT_PROVIDED)
      expect(parameter.default_generator.call.call).to eq(1)
      expect(parameter.optional?).to be(true)
    end

    it "accepts a callable for 'default_generator'" do
      parameter = described_class.make(:attr_name, default_generator: -> { 1 })

      expect(parameter.default_generator).not_to eq(Strict::Parameter::NOT_PROVIDED)
      expect(parameter.default_generator.call).to eq(1)
      expect(parameter.optional?).to be(true)
    end

    it "does not accept multiple defaults" do
      expect do
        described_class.make(:attr_name, default: 1, default_value: 1)
      end.to raise_error(ArgumentError)
    end

    it "requires a supported parameter coercer" do
      [nil, true, :coerce, 1, Object.new].each do |coercer|
        expect { described_class.make(:attr_name, coerce: coercer) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#valid?" do
    it "uses the validator to check if the value is valid" do
      parameter = described_class.make(:attr_name, Strict::Validators::Boolean.instance)

      expect(parameter.valid?(true)).to be(true)
      expect(parameter.valid?(false)).to be(true)
      expect(parameter.valid?(nil)).to be(false)
      expect(parameter.valid?(1)).to be(false)

      parameter = described_class.make(
        :attr_name,
        Strict::Validators::AnyOf.new(Strict::Validators::Boolean.instance, nil)
      )

      expect(parameter.valid?(true)).to be(true)
      expect(parameter.valid?(false)).to be(true)
      expect(parameter.valid?(nil)).to be(true)
      expect(parameter.valid?(1)).to be(false)
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
      parameter = described_class.make(:attr_name, validator)

      expect(validator.called).to be(false)
      Strict.with_overrides(sample_rate: 0) do
        expect(parameter.valid?(true)).to be(true)
        expect(validator.called).to be(false)
        expect(parameter.valid?(false)).to be(true)
        expect(validator.called).to be(false)
        expect(parameter.valid?(nil)).to be(true)
        expect(validator.called).to be(false)
        expect(parameter.valid?(1)).to be(true)
        expect(validator.called).to be(false)
      end

      Strict.with_overrides(sample_rate: 1) do
        expect(parameter.valid?(nil)).to be(false)
        expect(validator.called).to be(true)
      end
    end
  end

  describe "#coerce" do
    it "returns the value if coercion is not enabled" do
      parameter = described_class.make(:attr_name, coerce: false)

      expect(parameter.coerce("value")).to eq("value")
    end

    it "calls the callable if one is passed" do
      parameter = described_class.make(:attr_name, coerce: ->(value) { "coerced #{value}" })

      expect(parameter.coerce("value")).to eq("coerced value")
    end
  end
end
