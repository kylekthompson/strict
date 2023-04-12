# frozen_string_literal: true

require "test_helper"

describe Strict::Return do
  describe ".make" do
    it "has defaults for the validator and coercion" do
      returns = Strict::Return.make

      assert_equal Strict::Validators::Anything.instance, returns.validator
      refute returns.coercer
    end

    it "accepts a combination of all arguments" do
      returns = Strict::Return.make(Strict::Validators::Boolean.instance, coerce: ->(value) { value + 1 })

      assert_equal Strict::Validators::Boolean.instance, returns.validator
      assert returns.coercer
    end

    it "accepts a validator" do
      returns = Strict::Return.make(Strict::Validators::Boolean.instance)

      assert_equal Strict::Validators::Boolean.instance, returns.validator
    end

    it "accepts a coerce value" do
      returns = Strict::Return.make(coerce: ->(value) { value + 1 })

      assert returns.coercer
    end

    it "does not accept a value for 'default'" do
      assert_raises(ArgumentError) do
        Strict::Return.make(default: 1)
      end
    end

    it "does not accept a value for 'default_value'" do
      assert_raises(ArgumentError) do
        Strict::Return.make(default_value: 1)
      end
    end

    it "does not accept a value for 'default_generator'" do
      assert_raises(ArgumentError) do
        Strict::Return.make(default_generator: -> { 1 })
      end
    end
  end

  describe "#valid?" do
    it "uses the validator to check if the value is valid" do
      returns = Strict::Return.make(Strict::Validators::Boolean.instance)

      assert returns.valid?(true)
      assert returns.valid?(false)
      refute returns.valid?(nil)
      refute returns.valid?(1)

      returns = Strict::Return.make(Strict::Validators::AnyOf.new(Strict::Validators::Boolean.instance, nil))

      assert returns.valid?(true)
      assert returns.valid?(false)
      assert returns.valid?(nil)
      refute returns.valid?(1)
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
      returns = Strict::Return.make(validator)

      refute validator.called
      Strict.with_overrides(sample_ratio: 0) do
        assert returns.valid?(true)
        refute validator.called
        assert returns.valid?(false)
        refute validator.called
        assert returns.valid?(nil)
        refute validator.called
        assert returns.valid?(1)
        refute validator.called
      end

      Strict.with_overrides(sample_ratio: 1) do
        refute returns.valid?(nil)
        assert validator.called
      end
    end
  end

  describe "#coerce" do
    it "returns the value if coercion is not enabled" do
      returns = Strict::Return.make(coerce: false)

      assert_equal "value", returns.coerce("value")
    end

    it "does not support .coerce_attr_name coercion" do
      returns = Strict::Return.make(coerce: true)

      assert_raises(NoMethodError) do
        returns.coerce("value")
      end
    end

    it "does not support coercion methods is passed" do
      returns = Strict::Return.make(coerce: :some_method)

      assert_raises(NoMethodError) do
        returns.coerce("value")
      end
    end

    it "calls the callable if one is passed" do
      returns = Strict::Return.make(coerce: ->(value) { "coerced #{value}" })

      assert_equal "coerced value", returns.coerce("value")
    end
  end
end
