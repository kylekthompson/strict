# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Attribute do
  describe ".make" do
    it "has defaults when only given a name" do
      attribute = described_class.make("attr_name")

      expect(attribute.name).to eq(:attr_name)
      expect(attribute.validator).to eq(Strict::Validators::Anything.instance)
      expect(attribute.default_generator).to eq(Strict::Attribute::NOT_PROVIDED)
      expect(attribute.coercer).to be_falsey
      expect(attribute.instance_variable).to eq(:@__strict_attribute_617474725f6e616d65)
      expect(attribute).not_to be_optional
    end

    it "accepts a combination of all arguments" do
      attribute = described_class.make(:attr_name, Strict::Validators::Boolean.instance, coerce: true, default: 1)

      expect(attribute.name).to eq(:attr_name)
      expect(attribute.validator).to eq(Strict::Validators::Boolean.instance)
      expect(attribute.default_generator).not_to eq(Strict::Attribute::NOT_PROVIDED)
      expect(attribute.default_generator.call).to eq(1)
      expect(attribute.coercer).to be_truthy
      expect(attribute.instance_variable).to eq(:@__strict_attribute_617474725f6e616d65)
      expect(attribute).to be_optional
    end

    it "accepts a validator" do
      attribute = described_class.make(:attr_name, Strict::Validators::Boolean.instance)

      expect(attribute.validator).to eq(Strict::Validators::Boolean.instance)
    end

    it "accepts a coerce value" do
      attribute = described_class.make(:attr_name, coerce: true)

      expect(attribute.coercer).to be_truthy
    end

    it "uses the validator's coercer by default" do
      coercer = ->(value) { value.to_s }
      validator = Object.new
      validator.define_singleton_method(:coercer) { coercer }

      attribute = described_class.make(:attr_name, validator)

      expect(attribute.coercer).to be(coercer)
    end

    it "allows the validator's coercer to be disabled" do
      validator = Object.new
      validator.define_singleton_method(:coercer) { ->(value) { value.to_s } }

      attribute = described_class.make(:attr_name, validator, coerce: false)

      expect(attribute.coercer).to be(false)
    end

    it "accepts a value for 'default'" do
      attribute = described_class.make(:attr_name, default: 1)

      expect(attribute.default_generator).not_to eq(Strict::Attribute::NOT_PROVIDED)
      expect(attribute.default_generator.call).to eq(1)
      expect(attribute).to be_optional
    end

    it "accepts a callable for 'default'" do
      attribute = described_class.make(:attr_name, default: -> { 1 })

      expect(attribute.default_generator).not_to eq(Strict::Attribute::NOT_PROVIDED)
      expect(attribute.default_generator.call).to eq(1)
      expect(attribute).to be_optional
    end

    it "accepts a value for 'default_value'" do
      attribute = described_class.make(:attr_name, default_value: -> { 1 })

      expect(attribute.default_generator).not_to eq(Strict::Attribute::NOT_PROVIDED)
      expect(attribute.default_generator.call.call).to eq(1)
      expect(attribute).to be_optional
    end

    it "accepts a callable for 'default_generator'" do
      attribute = described_class.make(:attr_name, default_generator: -> { 1 })

      expect(attribute.default_generator).not_to eq(Strict::Attribute::NOT_PROVIDED)
      expect(attribute.default_generator.call).to eq(1)
      expect(attribute).to be_optional
    end

    it "does not accept multiple defaults" do
      expect do
        described_class.make(:attr_name, default: 1, default_value: 1)
      end.to raise_error(ArgumentError)
    end

    it "requires a supported declaration name" do
      [nil, 1, "", :+, :"attr_name=", :"two words", :"attr[]"].each do |name|
        expect { described_class.make(name) }.to raise_error(ArgumentError)
      end
    end

    it "requires an explicit default generator to be callable" do
      expect do
        described_class.make(:attr_name, default_generator: "not callable")
      end.to raise_error(ArgumentError)
    end

    it "requires a supported attribute coercer" do
      [nil, 1, "coerce", Object.new].each do |coercer|
        expect { described_class.make(:attr_name, coerce: coercer) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#valid?" do
    it "uses the validator to check if the value is valid" do
      attribute = described_class.make(:attr_name, Strict::Validators::Boolean.instance)

      expect(attribute.valid?(true)).to be(true)
      expect(attribute.valid?(false)).to be(true)
      expect(attribute.valid?(nil)).to be(false)
      expect(attribute.valid?(1)).to be(false)

      attribute = described_class.make(
        :attr_name,
        Strict::Validators::AnyOf.new(Strict::Validators::Boolean.instance, nil)
      )

      expect(attribute.valid?(true)).to be(true)
      expect(attribute.valid?(false)).to be(true)
      expect(attribute.valid?(nil)).to be(true)
      expect(attribute.valid?(1)).to be(false)
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
      attribute = described_class.make(:attr_name, validator)

      expect(validator.called).to be(false)
      Strict.with_overrides(sample_rate: 0) do
        expect(attribute.valid?(true)).to be(true)
        expect(validator.called).to be(false)
        expect(attribute.valid?(false)).to be(true)
        expect(validator.called).to be(false)
        expect(attribute.valid?(nil)).to be(true)
        expect(validator.called).to be(false)
        expect(attribute.valid?(1)).to be(true)
        expect(validator.called).to be(false)
      end

      Strict.with_overrides(sample_rate: 1) do
        expect(attribute.valid?(nil)).to be(false)
        expect(validator.called).to be(true)
      end
    end
  end

  describe "#coerce" do
    it "returns the value if coercion is not enabled" do
      attribute = described_class.make(:attr_name, coerce: false)

      expect(attribute.coerce("value", for_class: nil)).to eq("value")
    end

    it "calls #coerce_attr_name if coercion is enabled" do
      attribute = described_class.make(:attr_name, coerce: true)

      value = attribute.coerce(
        "value",
        for_class: Module.new { def self.coerce_attr_name(value) = "coerced #{value}" }
      )

      expect(value).to eq("coerced value")
    end

    it "calls the method name if a coercion method is passed" do
      attribute = described_class.make(:attr_name, coerce: :some_method)

      value = attribute.coerce(
        "value",
        for_class: Module.new { def self.some_method(value) = "coerced #{value}" }
      )

      expect(value).to eq("coerced value")
    end

    it "calls the callable if one is passed" do
      attribute = described_class.make(:attr_name, coerce: ->(value) { "coerced #{value}" })

      expect(attribute.coerce("value", for_class: nil)).to eq("coerced value")
    end
  end
end
