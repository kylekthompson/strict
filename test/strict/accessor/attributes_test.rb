# frozen_string_literal: true

require "test_helper"

describe Strict::Accessor::Attributes do
  before do
    @accessor_class = Class.new do
      extend Strict::Accessor::Attributes

      attributes do
        foo Integer
        bar String, coerce: :some_coercer
        baz String, default: "some string"
      end

      def self.some_coercer(value)
        value.to_s
      end
    end
  end

  it "exposes the configuration on the class" do
    assert_equal Strict::Attributes::Configuration, @accessor_class.strict_attributes.class
    assert_equal %i[foo bar baz], @accessor_class.strict_attributes.map(&:name)
  end

  it "exposes writer methods" do
    instance = @accessor_class.new(foo: 1, bar: "2", baz: "3")
    instance.foo = 2
    assert_equal 2, instance.foo
  end

  it "exposes reader methods" do
    instance = @accessor_class.new(foo: 1, bar: "2", baz: "3")
    assert_equal 1, instance.foo
  end

  it "does not allow invalid arguments at initialization" do
    error = assert_raises(Strict::InitializationError) do
      @accessor_class.new(foo: "1", bar: "2", baz: "3")
    end

    assert_match(/foo/, error.message)
  end

  it "coerces arguments that can be coerced at initialization" do
    instance = @accessor_class.new(foo: 1, bar: 2, baz: "3")
    assert_equal "2", instance.bar
  end

  it "does not require optional attributes at initialization" do
    instance = @accessor_class.new(foo: 1, bar: "2")
    assert_equal "some string", instance.baz
  end

  it "requires mandatory attributes at initialization" do
    error = assert_raises(Strict::InitializationError) do
      @accessor_class.new(foo: 1, baz: "3")
    end

    assert_match(/bar/, error.message)
  end

  it "does not allow additional attributes at initialization" do
    error = assert_raises(Strict::InitializationError) do
      @accessor_class.new(foo: 1, bar: "2", baz: "3", bat: "uh oh")
    end

    assert_match(/bat/, error.message)
  end

  it "aggregates errors at initialization" do
    error = assert_raises(Strict::InitializationError) do
      @accessor_class.new(foo: "1", baz: "3", bat: "uh oh")
    end

    assert_match(/foo/, error.message)
    assert_match(/bar/, error.message)
    assert_match(/bat/, error.message)
  end

  it "does not allow invalid arguments at assignment" do
    instance = @accessor_class.new(foo: 1, bar: "2", baz: "3")

    error = assert_raises(Strict::AssignmentError) do
      instance.foo = "1"
    end

    assert_match(/foo/, error.message)
  end

  it "coerces arguments that can be coerced at assignment" do
    instance = @accessor_class.new(foo: 1, bar: "2", baz: "3")
    instance.bar = 3
    assert_equal "3", instance.bar
  end
end
