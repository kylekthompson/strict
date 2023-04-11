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
        coerce_array coerce: ToArray()
        coerce_array_with coerce: ToArray(with: ->(element) { element.to_s })
        coerce_hash coerce: ToHash()
        coerce_hash_with coerce: ToHash(
          with_keys: ->(element) { element.to_s },
          with_values: ->(element) { element.to_s }
        )
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
      assert_equal [[:one, 1]], configuration.named!(:coerce_array).coerce({ one: 1 }, for_class: nil)
      assert_equal %w[1 2], configuration.named!(:coerce_array_with).coerce([1, 2], for_class: nil)
      assert_equal({ one: 1 }, configuration.named!(:coerce_hash).coerce([[:one, 1]], for_class: nil))
      assert_equal({ "one" => "1" }, configuration.named!(:coerce_hash_with).coerce([[:one, 1]], for_class: nil))
      assert_instance_of Strict::Validators::AllOf, configuration.named!(:all_of).validator
      assert_instance_of Strict::Validators::AnyOf, configuration.named!(:any_of).validator
      assert_instance_of Strict::Validators::Anything, configuration.named!(:anything).validator
      assert_instance_of Strict::Validators::ArrayOf, configuration.named!(:array_of).validator
      assert_instance_of Strict::Validators::Boolean, configuration.named!(:boolean).validator
      assert_instance_of Strict::Validators::HashOf, configuration.named!(:hash_of).validator
      assert_instance_of Strict::Validators::RangeOf, configuration.named!(:range_of).validator
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
