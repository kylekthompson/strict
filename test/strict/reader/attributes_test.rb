# frozen_string_literal: true

require "test_helper"

describe Strict::Reader::Attributes do
  before do
    @reader_class = Class.new do
      extend Strict::Reader::Attributes

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
    assert_equal Strict::Attributes::Configuration, @reader_class.strict_attributes.class
    assert_equal %i[foo bar baz], @reader_class.strict_attributes.map(&:name)
  end

  it "does not expose writer methods" do
    instance = @reader_class.new(foo: 1, bar: "2", baz: "3")

    assert_raises(NoMethodError) do
      instance.foo = 1
    end
  end

  it "exposes reader methods" do
    instance = @reader_class.new(foo: 1, bar: "2", baz: "3")
    assert_equal 1, instance.foo
  end

  it "does not allow invalid arguments" do
    error = assert_raises(Strict::InitializationError) do
      @reader_class.new(foo: "1", bar: "2", baz: "3")
    end

    assert_match(/foo/, error.message)
  end

  it "coerces arguments that can be coerced" do
    instance = @reader_class.new(foo: 1, bar: 2, baz: "3")
    assert_equal "2", instance.bar
  end

  it "does not require optional attributes" do
    instance = @reader_class.new(foo: 1, bar: "2")
    assert_equal "some string", instance.baz
  end

  it "requires mandatory attributes" do
    error = assert_raises(Strict::InitializationError) do
      @reader_class.new(foo: 1, baz: "3")
    end

    assert_match(/bar/, error.message)
  end

  it "does not allow additional attributes" do
    error = assert_raises(Strict::InitializationError) do
      @reader_class.new(foo: 1, bar: "2", baz: "3", bat: "uh oh")
    end

    assert_match(/bat/, error.message)
  end

  it "aggregates errors" do
    error = assert_raises(Strict::InitializationError) do
      @reader_class.new(foo: "1", baz: "3", bat: "uh oh")
    end

    assert_match(/foo/, error.message)
    assert_match(/bar/, error.message)
    assert_match(/bat/, error.message)
  end
end
