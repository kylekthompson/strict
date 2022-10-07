# frozen_string_literal: true

require "test_helper"

describe Strict::Parameter do
  describe ".make" do
    it "has defaults when only given a name" do
      parameter = Strict::Parameter.make("attr_name")

      assert_equal :attr_name, parameter.name
      assert_equal Strict::Validators::Anything.instance, parameter.validator
      assert_equal Strict::Parameter::NOT_PROVIDED, parameter.default_generator
      refute parameter.coercer
      refute_predicate parameter, :optional?
    end

    it "accepts a combination of all arguments" do
      parameter = Strict::Parameter.make(
        :attr_name,
        Strict::Validators::Boolean.instance,
        coerce: ->(value) { value + 1 },
        default: 1
      )

      assert_equal :attr_name, parameter.name
      assert_equal Strict::Validators::Boolean.instance, parameter.validator
      refute_equal Strict::Parameter::NOT_PROVIDED, parameter.default_generator
      assert_equal 1, parameter.default_generator.call
      assert parameter.coercer
      assert_predicate parameter, :optional?
    end

    it "accepts a validator" do
      parameter = Strict::Parameter.make(:attr_name, Strict::Validators::Boolean.instance)

      assert_equal Strict::Validators::Boolean.instance, parameter.validator
    end

    it "accepts a coerce value" do
      parameter = Strict::Parameter.make(:attr_name, coerce: ->(value) { value + 1 })

      assert parameter.coercer
    end

    it "accepts a value for 'default'" do
      parameter = Strict::Parameter.make(:attr_name, default: 1)

      refute_equal Strict::Parameter::NOT_PROVIDED, parameter.default_generator
      assert_equal 1, parameter.default_generator.call
      assert_predicate parameter, :optional?
    end

    it "accepts a callable for 'default'" do
      parameter = Strict::Parameter.make(:attr_name, default: -> { 1 })

      refute_equal Strict::Parameter::NOT_PROVIDED, parameter.default_generator
      assert_equal 1, parameter.default_generator.call
      assert_predicate parameter, :optional?
    end

    it "accepts a value for 'default_value'" do
      parameter = Strict::Parameter.make(:attr_name, default_value: -> { 1 })

      refute_equal Strict::Parameter::NOT_PROVIDED, parameter.default_generator
      assert_equal 1, parameter.default_generator.call.call
      assert_predicate parameter, :optional?
    end

    it "accepts a callable for 'default_generator'" do
      parameter = Strict::Parameter.make(:attr_name, default_generator: -> { 1 })

      refute_equal Strict::Parameter::NOT_PROVIDED, parameter.default_generator
      assert_equal 1, parameter.default_generator.call
      assert_predicate parameter, :optional?
    end

    it "does not accept multiple defaults" do
      assert_raises(ArgumentError) do
        Strict::Parameter.make(:attr_name, default: 1, default_value: 1)
      end
    end
  end

  describe "#valid?" do
    it "uses the validator to check if the value is valid" do
      parameter = Strict::Parameter.make(:attr_name, Strict::Validators::Boolean.instance)

      assert parameter.valid?(true)
      assert parameter.valid?(false)
      refute parameter.valid?(nil)
      refute parameter.valid?(1)

      parameter = Strict::Parameter.make(
        :attr_name,
        Strict::Validators::AnyOf.new(Strict::Validators::Boolean.instance, nil)
      )

      assert parameter.valid?(true)
      assert parameter.valid?(false)
      assert parameter.valid?(nil)
      refute parameter.valid?(1)
    end
  end

  describe "#coerce" do
    it "returns the value if coercion is not enabled" do
      parameter = Strict::Parameter.make(:attr_name, coerce: false)

      assert_equal "value", parameter.coerce("value")
    end

    it "does not support .coerce_attr_name coercion" do
      parameter = Strict::Parameter.make(:attr_name, coerce: true)

      assert_raises(NoMethodError) do
        parameter.coerce("value")
      end
    end

    it "does not support coercion methods is passed" do
      parameter = Strict::Parameter.make(:attr_name, coerce: :some_method)

      assert_raises(NoMethodError) do
        parameter.coerce("value")
      end
    end

    it "calls the callable if one is passed" do
      parameter = Strict::Parameter.make(:attr_name, coerce: ->(value) { "coerced #{value}" })

      assert_equal "coerced value", parameter.coerce("value")
    end
  end
end
