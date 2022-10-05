# frozen_string_literal: true

require "test_helper"

describe Strict::Attributes::Dsl do
  describe ".run" do
    it "creates a recipe with valid identifiers and arguments" do
      recipe = Strict::Attributes::Dsl.run do
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
      attributes = recipe.attributes.to_h { |a| [a.name, a] }

      assert_equal Strict::Validators::Anything.instance, attributes.fetch(:no_arguments).validator
      refute_nil attributes.fetch(:_underscore_identifier)
      refute_nil attributes.fetch(:question?)
      refute_nil attributes.fetch(:unsafe!)
      assert_equal 1, attributes.fetch(:default_with_value).default_generator.call
      assert_equal 1, attributes.fetch(:default_with_callable).default_generator.call
      assert_equal 1, attributes.fetch(:default_value).default_generator.call
      assert_equal 1, attributes.fetch(:default_generator).default_generator.call
      assert_equal "coerced value", attributes.fetch(:coerce).coerce(
        "value",
        for_class: Module.new { def self.coerce_coerce(value) = "coerced #{value}" }
      )
      assert_equal "coerced value", attributes.fetch(:coerce_method).coerce(
        "value",
        for_class: Module.new { def self.some_method(value) = "coerced #{value}" }
      )
      assert_equal Strict::Validators::AllOf, attributes.fetch(:all_of).validator.class
      assert_equal Strict::Validators::AnyOf, attributes.fetch(:any_of).validator.class
      assert_equal Strict::Validators::Anything, attributes.fetch(:anything).validator.class
      assert_equal Strict::Validators::ArrayOf, attributes.fetch(:array_of).validator.class
      assert_equal Strict::Validators::Boolean, attributes.fetch(:boolean).validator.class
      assert_equal Strict::Validators::HashOf, attributes.fetch(:hash_of).validator.class
      assert_equal Strict::Validators::RangeOf, attributes.fetch(:range_of).validator.class
    end

    it "allows overwriting attributes" do
      recipe = Strict::Attributes::Dsl.run do
        foo String
        foo Integer
      end

      assert_equal %i[foo foo], recipe.attributes.map(&:name)
      assert_equal [String, Integer], recipe.attributes.map(&:validator)
    end

    it "allows manually creating attributes" do
      recipe = Strict::Attributes::Dsl.run do
        strict_attribute :if
      end

      assert_equal [:if], recipe.attributes.map(&:name)
    end
  end
end
