# frozen_string_literal: true

require "test_helper"

class ReaderClass
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

describe Strict::Reader::Attributes do
  it "exposes the configuration on the class" do
    assert_equal Strict::Attributes::Configuration, ReaderClass.strict_attributes.class
    assert_equal %i[foo bar baz], ReaderClass.strict_attributes.map(&:name)
  end

  it "does not expose writer methods" do
    instance = ReaderClass.new(foo: 1, bar: "2", baz: "3")

    assert_raises(NoMethodError) do
      instance.foo = 1
    end
  end

  it "exposes reader methods" do
    instance = ReaderClass.new(foo: 1, bar: "2", baz: "3")
    assert_equal 1, instance.foo
  end

  it "does not allow invalid arguments" do
    error = assert_raises(Strict::InitializationError) do
      ReaderClass.new(foo: "1", bar: "2", baz: "3")
    end

    assert_match(/foo/, error.message)
  end

  it "coerces arguments that can be coerced" do
    instance = ReaderClass.new(foo: 1, bar: 2, baz: "3")
    assert_equal "2", instance.bar
  end

  it "does not require optional attributes" do
    instance = ReaderClass.new(foo: 1, bar: "2")
    assert_equal "some string", instance.baz
  end

  it "requires mandatory attributes" do
    error = assert_raises(Strict::InitializationError) do
      ReaderClass.new(foo: 1, baz: "3")
    end

    assert_match(/bar/, error.message)
  end

  it "does not allow additional attributes" do
    error = assert_raises(Strict::InitializationError) do
      ReaderClass.new(foo: 1, bar: "2", baz: "3", bat: "uh oh")
    end

    assert_match(/bat/, error.message)
  end

  it "aggregates errors" do
    error = assert_raises(Strict::InitializationError) do
      ReaderClass.new(foo: "1", baz: "3", bat: "uh oh")
    end

    assert_match(/foo/, error.message)
    assert_match(/bar/, error.message)
    assert_match(/bat/, error.message)
  end

  it "turns into a hash of attributes" do
    instance = ReaderClass.new(foo: 1, bar: "2", baz: "3")

    assert_equal({ foo: 1, bar: "2", baz: "3" }, instance.to_h)
  end

  it "can be inspected" do
    instance = ReaderClass.new(foo: 1, bar: "2", baz: "3")
    assert_equal "#<ReaderClass foo=1 bar=\"2\" baz=\"3\">", instance.inspect
  end

  it "can be pretty printed" do
    instance = ReaderClass.new(foo: 1, bar: "2", baz: "3")
    output = StringIO.new
    PP.pp(instance, output, 5)
    assert_equal <<~OUTPUT, output.string
      #<ReaderClass
       foo=1
       bar="2"
       baz="3">
    OUTPUT
  end

  it "exposes a coercer" do
    instance = ReaderClass.coercer.call(foo: 1, bar: "2", baz: "3")
    assert_equal ReaderClass, instance.class
    assert_equal 1, instance.foo
    assert_equal "2", instance.bar
    assert_equal "3", instance.baz

    instance = ReaderClass.coercer.call("1")
    assert_equal "1", instance

    assert_raises(Strict::InitializationError) do
      ReaderClass.coercer.call({})
    end
  end
end
