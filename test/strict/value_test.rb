# frozen_string_literal: true

require "test_helper"

class ValueClass
  include Strict::Value

  attributes do
    foo Integer
    bar String, coerce: :some_coercer
    baz String, default: "some string"
  end

  def self.some_coercer(value)
    value.to_s
  end
end

describe Strict::Value do
  before do
    @other_value_class = Class.new do
      include Strict::Value

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
    assert_equal Strict::Attributes::Configuration, ValueClass.strict_attributes.class
    assert_equal %i[foo bar baz], ValueClass.strict_attributes.map(&:name)
  end

  it "does not expose writer methods" do
    instance = ValueClass.new(foo: 1, bar: "2", baz: "3")

    assert_raises(NoMethodError) do
      instance.foo = 1
    end
  end

  it "exposes reader methods" do
    instance = ValueClass.new(foo: 1, bar: "2", baz: "3")

    assert_equal 1, instance.foo
  end

  it "does not allow invalid arguments" do
    error = assert_raises(Strict::InitializationError) do
      ValueClass.new(foo: "1", bar: "2", baz: "3")
    end

    assert_match(/foo/, error.message)
  end

  it "coerces arguments that can be coerced" do
    instance = ValueClass.new(foo: 1, bar: 2, baz: "3")

    assert_equal "2", instance.bar
  end

  it "does not require optional attributes" do
    instance = ValueClass.new(foo: 1, bar: "2")

    assert_equal "some string", instance.baz
  end

  it "requires mandatory attributes" do
    error = assert_raises(Strict::InitializationError) do
      ValueClass.new(foo: 1, baz: "3")
    end

    assert_match(/bar/, error.message)
  end

  it "does not allow additional attributes" do
    error = assert_raises(Strict::InitializationError) do
      ValueClass.new(foo: 1, bar: "2", baz: "3", bat: "uh oh")
    end

    assert_match(/bat/, error.message)
  end

  it "aggregates errors" do
    error = assert_raises(Strict::InitializationError) do
      ValueClass.new(foo: "1", baz: "3", bat: "uh oh")
    end

    assert_match(/foo/, error.message)
    assert_match(/bar/, error.message)
    assert_match(/bat/, error.message)
  end

  it "implements equality" do
    value_instance_one = ValueClass.new(foo: 1, bar: "2", baz: "3")
    value_instance_two = ValueClass.new(foo: 1, bar: "2", baz: "3")
    value_instance_three = ValueClass.new(foo: 1, bar: "2", baz: "4")
    other_value_instance_one = @other_value_class.new(foo: 1, bar: "2", baz: "3")

    assert_equal value_instance_one, value_instance_one
    assert_equal value_instance_one, value_instance_two
    assert_equal value_instance_two, value_instance_one
    refute_equal value_instance_three, value_instance_one
    refute_equal value_instance_one, value_instance_three
    refute_equal value_instance_one, other_value_instance_one
  end

  it "is hashable" do
    value_instance_one = ValueClass.new(foo: 1, bar: "2", baz: "3")
    value_instance_two = ValueClass.new(foo: 1, bar: "2", baz: "3")
    value_instance_three = ValueClass.new(foo: 1, bar: "2", baz: "4")
    other_value_instance_one = @other_value_class.new(foo: 1, bar: "2", baz: "3")

    hash = {}
    hash[value_instance_one] = 1
    hash[value_instance_two] = 2
    hash[value_instance_three] = 3
    hash[other_value_instance_one] = 4

    assert_equal 2, hash[value_instance_one]
    assert_equal 2, hash[value_instance_two]
    assert_equal 3, hash[value_instance_three]
    assert_equal 4, hash[other_value_instance_one]
  end

  it "is clonable" do
    instance = ValueClass.new(foo: 1, bar: "2", baz: "3")
    cloned = instance.with(foo: 2)

    assert_equal 1, instance.foo
    assert_equal 2, cloned.foo
    assert_equal "2", cloned.bar
    assert_equal "3", cloned.baz

    assert_raises(Strict::InitializationError) do
      instance.with(foo: "1")
    end
  end

  it "turns into a hash of attributes" do
    instance = ValueClass.new(foo: 1, bar: "2", baz: "3")

    assert_equal({ foo: 1, bar: "2", baz: "3" }, instance.to_h)
  end

  it "can be inspected" do
    instance = ValueClass.new(foo: 1, bar: "2", baz: "3")

    assert_equal "#<ValueClass foo=1 bar=\"2\" baz=\"3\">", instance.inspect
  end

  it "can be pretty printed" do
    instance = ValueClass.new(foo: 1, bar: "2", baz: "3")
    output = StringIO.new
    PP.pp(instance, output, 5)

    assert_equal <<~OUTPUT, output.string
      #<ValueClass
       foo=1
       bar="2"
       baz="3">
    OUTPUT
  end

  it "exposes a coercer" do
    instance = ValueClass.coercer.call(foo: 1, bar: "2", baz: "3")

    assert_equal ValueClass, instance.class
    assert_equal 1, instance.foo
    assert_equal "2", instance.bar
    assert_equal "3", instance.baz

    instance = ValueClass.coercer.call("1")

    assert_equal "1", instance

    assert_raises(Strict::InitializationError) do
      ValueClass.coercer.call({})
    end
  end
end
