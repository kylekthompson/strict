# frozen_string_literal: true

require "test_helper"

describe Strict::Attribute do
  describe ".make" do
    it "has defaults when only given a name" do
      attribute = Strict::Attribute.make("attr_name")

      assert_equal :attr_name, attribute.name
      assert_equal Strict::Validators::Anything.instance, attribute.validator
      assert_equal Strict::Attribute::NOT_PROVIDED, attribute.default_generator
      refute attribute.coercer
      assert_equal "@attr_name", attribute.instance_variable
      refute_predicate attribute, :optional?
    end

    it "accepts a combination of all arguments" do
      attribute = Strict::Attribute.make(:attr_name, Strict::Validators::Boolean.instance, coerce: true, default: 1)

      assert_equal :attr_name, attribute.name
      assert_equal Strict::Validators::Boolean.instance, attribute.validator
      refute_equal Strict::Attribute::NOT_PROVIDED, attribute.default_generator
      assert_equal 1, attribute.default_generator.call
      assert attribute.coercer
      assert_equal "@attr_name", attribute.instance_variable
      assert_predicate attribute, :optional?
    end

    it "accepts a validator" do
      attribute = Strict::Attribute.make(:attr_name, Strict::Validators::Boolean.instance)

      assert_equal Strict::Validators::Boolean.instance, attribute.validator
    end

    it "accepts a coerce value" do
      attribute = Strict::Attribute.make(:attr_name, coerce: true)

      assert attribute.coercer
    end

    it "accepts a value for 'default'" do
      attribute = Strict::Attribute.make(:attr_name, default: 1)

      refute_equal Strict::Attribute::NOT_PROVIDED, attribute.default_generator
      assert_equal 1, attribute.default_generator.call
      assert_predicate attribute, :optional?
    end

    it "accepts a callable for 'default'" do
      attribute = Strict::Attribute.make(:attr_name, default: -> { 1 })

      refute_equal Strict::Attribute::NOT_PROVIDED, attribute.default_generator
      assert_equal 1, attribute.default_generator.call
      assert_predicate attribute, :optional?
    end

    it "accepts a value for 'default_value'" do
      attribute = Strict::Attribute.make(:attr_name, default_value: -> { 1 })

      refute_equal Strict::Attribute::NOT_PROVIDED, attribute.default_generator
      assert_equal 1, attribute.default_generator.call.call
      assert_predicate attribute, :optional?
    end

    it "accepts a callable for 'default_generator'" do
      attribute = Strict::Attribute.make(:attr_name, default_generator: -> { 1 })

      refute_equal Strict::Attribute::NOT_PROVIDED, attribute.default_generator
      assert_equal 1, attribute.default_generator.call
      assert_predicate attribute, :optional?
    end

    it "does not accept multiple defaults" do
      assert_raises(ArgumentError) do
        Strict::Attribute.make(:attr_name, default: 1, default_value: 1)
      end
    end
  end

  describe "#valid?" do
    it "uses the validator to check if the value is valid" do
      attribute = Strict::Attribute.make(:attr_name, Strict::Validators::Boolean.instance)

      assert attribute.valid?(true)
      assert attribute.valid?(false)
      refute attribute.valid?(nil)
      refute attribute.valid?(1)

      attribute = Strict::Attribute.make(
        :attr_name,
        Strict::Validators::AnyOf.new(Strict::Validators::Boolean.instance, nil)
      )

      assert attribute.valid?(true)
      assert attribute.valid?(false)
      assert attribute.valid?(nil)
      refute attribute.valid?(1)
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
      attribute = Strict::Attribute.make(:attr_name, validator)

      refute validator.called
      Strict.with_overrides(sample_rate: 0) do
        assert attribute.valid?(true)
        refute validator.called
        assert attribute.valid?(false)
        refute validator.called
        assert attribute.valid?(nil)
        refute validator.called
        assert attribute.valid?(1)
        refute validator.called
      end

      Strict.with_overrides(sample_rate: 1) do
        refute attribute.valid?(nil)
        assert validator.called
      end
    end
  end

  describe "#coerce" do
    it "returns the value if coercion is not enabled" do
      attribute = Strict::Attribute.make(:attr_name, coerce: false)

      assert_equal "value", attribute.coerce("value", for_class: nil)
    end

    it "calls #coerce_attr_name if coercion is enabled" do
      attribute = Strict::Attribute.make(:attr_name, coerce: true)

      assert_equal "coerced value", attribute.coerce(
        "value",
        for_class: Module.new { def self.coerce_attr_name(value) = "coerced #{value}" }
      )
    end

    it "calls the method name if a coercion method is passed" do
      attribute = Strict::Attribute.make(:attr_name, coerce: :some_method)

      assert_equal "coerced value", attribute.coerce(
        "value",
        for_class: Module.new { def self.some_method(value) = "coerced #{value}" }
      )
    end

    it "calls the callable if one is passed" do
      attribute = Strict::Attribute.make(:attr_name, coerce: ->(value) { "coerced #{value}" })

      assert_equal "coerced value", attribute.coerce("value", for_class: nil)
    end
  end
end
