# frozen_string_literal: true

require "test_helper"

describe Strict::Methods::Dsl do
  describe ".run" do
    it "creates a configuration with valid identifiers and arguments" do
      configuration = Strict::Methods::Dsl.run do
        no_arguments
        _underscore_identifier
        question?
        unsafe!
        default_with_value default: 1
        default_with_callable default: -> { 1 }
        default_value default_value: 1
        default_generator default_generator: -> { 1 }
        coerce coerce: ->(value) { "coerced #{value}" }
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
        returns Boolean()
      end
      parameters = configuration.parameters.to_h { |p| [p.name, p] }

      assert_equal Strict::Validators::Anything.instance, parameters.fetch(:no_arguments).validator
      refute_nil parameters.fetch(:_underscore_identifier)
      refute_nil parameters.fetch(:question?)
      refute_nil parameters.fetch(:unsafe!)
      assert_equal 1, parameters.fetch(:default_with_value).default_generator.call
      assert_equal 1, parameters.fetch(:default_with_callable).default_generator.call
      assert_equal 1, parameters.fetch(:default_value).default_generator.call
      assert_equal 1, parameters.fetch(:default_generator).default_generator.call
      assert_equal "coerced value", parameters.fetch(:coerce).coerce("value")
      assert_equal [[:one, 1]], parameters.fetch(:coerce_array).coerce({ one: 1 })
      assert_equal %w[1 2], parameters.fetch(:coerce_array_with).coerce([1, 2])
      assert_equal({ one: 1 }, parameters.fetch(:coerce_hash).coerce([[:one, 1]]))
      assert_equal({ "one" => "1" }, parameters.fetch(:coerce_hash_with).coerce([[:one, 1]]))
      assert_equal Strict::Validators::AllOf, parameters.fetch(:all_of).validator.class
      assert_equal Strict::Validators::AnyOf, parameters.fetch(:any_of).validator.class
      assert_equal Strict::Validators::Anything, parameters.fetch(:anything).validator.class
      assert_equal Strict::Validators::ArrayOf, parameters.fetch(:array_of).validator.class
      assert_equal Strict::Validators::Boolean, parameters.fetch(:boolean).validator.class
      assert_equal Strict::Validators::HashOf, parameters.fetch(:hash_of).validator.class
      assert_equal Strict::Validators::RangeOf, parameters.fetch(:range_of).validator.class
      assert_equal Strict::Validators::Boolean, configuration.returns.validator.class
    end

    it "allows overwriting parameters" do
      configuration = Strict::Methods::Dsl.run do
        foo String
        foo Integer
      end

      assert_equal %i[foo], configuration.parameters.map(&:name)
      assert_equal [Integer], configuration.parameters.map(&:validator)
    end

    it "allows manually creating parameters" do
      configuration = Strict::Methods::Dsl.run do
        strict_parameter :if
      end

      assert_equal [:if], configuration.parameters.map(&:name)
    end

    it "allows conflicting returns parameters and declarations" do
      configuration = Strict::Methods::Dsl.run do
        strict_parameter :returns, Integer
        returns Boolean()
      end
      parameters = configuration.parameters.to_h { |p| [p.name, p] }

      assert_equal Integer, parameters.fetch(:returns).validator
      assert_equal Strict::Validators::Boolean, configuration.returns.validator.class
    end

    it "defines returns as anything when not specified" do
      configuration = Strict::Methods::Dsl.run do
        foo String
      end

      assert_equal Strict::Validators::Anything, configuration.returns.validator.class
    end
  end
end
