# frozen_string_literal: true

require "test_helper"

describe Strict::Attributes::Dsl do
  describe ".run" do
    it "creates a configuration with valid identifiers and arguments" do
      configuration = Strict::Attributes::Dsl.run do
        no_arguments
        _underscore_identifier
        question?
        unsafe!
        default_with_value default: 1
        default_with_callable default: -> { 1 }
        default_value default_value: 1
        default_generator default_generator: -> { 1 }
        coerce coerce: true
        coerce_method coerce: :some_method
        all_of AllOf(Enumerable, Comparable)
        any_of AnyOf(Integer, String, nil)
        anything Anything()
        array_of ArrayOf(Anything())
        boolean Boolean()
        hash_of HashOf(Integer => String)
        range_of RangeOf(Numeric)
      end

      assert_equal Strict::Validators::Anything.instance, configuration.named!(:no_arguments).validator
      refute_nil configuration.named!(:_underscore_identifier)
      refute_nil configuration.named!(:question?)
      refute_nil configuration.named!(:unsafe!)
      assert_equal 1, configuration.named!(:default_with_value).default_generator.call
      assert_equal 1, configuration.named!(:default_with_callable).default_generator.call
      assert_equal 1, configuration.named!(:default_value).default_generator.call
      assert_equal 1, configuration.named!(:default_generator).default_generator.call
      assert_equal "coerced value", configuration.named!(:coerce).coerce(
        "value",
        for_class: Module.new { def self.coerce_coerce(value) = "coerced #{value}" }
      )
      assert_equal "coerced value", configuration.named!(:coerce_method).coerce(
        "value",
        for_class: Module.new { def self.some_method(value) = "coerced #{value}" }
      )
      assert_equal Strict::Validators::AllOf, configuration.named!(:all_of).validator.class
      assert_equal Strict::Validators::AnyOf, configuration.named!(:any_of).validator.class
      assert_equal Strict::Validators::Anything, configuration.named!(:anything).validator.class
      assert_equal Strict::Validators::ArrayOf, configuration.named!(:array_of).validator.class
      assert_equal Strict::Validators::Boolean, configuration.named!(:boolean).validator.class
      assert_equal Strict::Validators::HashOf, configuration.named!(:hash_of).validator.class
      assert_equal Strict::Validators::RangeOf, configuration.named!(:range_of).validator.class
    end

    it "allows overwriting attributes" do
      configuration = Strict::Attributes::Dsl.run do
        foo String
        foo Integer
      end

      assert_equal %i[foo], configuration.map(&:name)
      assert_equal [Integer], configuration.map(&:validator)
    end

    it "allows manually creating attributes" do
      configuration = Strict::Attributes::Dsl.run do
        strict_attribute :if
      end

      assert_equal [:if], configuration.map(&:name)
    end
  end
end
