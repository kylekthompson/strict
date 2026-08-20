# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Value do
  it "exposes the configuration on the class" do
    expect(ValueClass.strict_attributes).to be_an_instance_of(Strict::Attributes::Configuration)
    expect(ValueClass.strict_attributes.map(&:name)).to eq(%i[foo bar baz])
  end

  it "does not expose writer methods" do
    instance = build(:value)

    expect do
      instance.foo = 1
    end.to raise_error(NoMethodError)
  end

  it "exposes reader methods" do
    instance = build(:value)

    expect(instance.foo).to eq(1)
  end

  it "does not allow invalid arguments" do
    error = nil
    expect do
      ValueClass.new(foo: "1", bar: "2", baz: "3")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("foo")
  end

  it "coerces arguments that can be coerced" do
    instance = build(:value, bar: 2)

    expect(instance.bar).to eq("2")
  end

  it "does not require optional attributes" do
    instance = ValueClass.new(foo: 1, bar: "2")

    expect(instance.baz).to eq("some string")
  end

  it "requires mandatory attributes" do
    error = nil
    expect do
      ValueClass.new(foo: 1, baz: "3")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("bar")
  end

  it "does not allow additional attributes" do
    error = nil
    expect do
      ValueClass.new(foo: 1, bar: "2", baz: "3", bat: "uh oh")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("bat")
  end

  it "aggregates errors" do
    error = nil
    expect do
      ValueClass.new(foo: "1", baz: "3", bat: "uh oh")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("foo")
    expect(error.message).to include("bar")
    expect(error.message).to include("bat")
  end

  it "implements equality" do
    value_instance_one = build(:value)
    value_instance_two = build(:value)
    value_instance_three = build(:value, baz: "4")
    other_value_instance_one = build(:other_value)

    expect(value_instance_one).to eq(value_instance_one) # rubocop:disable RSpec/IdenticalEqualityAssertion
    expect(value_instance_two).to eq(value_instance_one)
    expect(value_instance_one).to eq(value_instance_two)
    expect(value_instance_one).not_to eq(value_instance_three)
    expect(value_instance_three).not_to eq(value_instance_one)
    expect(other_value_instance_one).not_to eq(value_instance_one)
  end

  it "is hashable" do
    value_instance_one = build(:value)
    value_instance_two = build(:value)
    value_instance_three = build(:value, baz: "4")
    other_value_instance_one = build(:other_value)

    hash = {}
    hash[value_instance_one] = 1
    hash[value_instance_two] = 2
    hash[value_instance_three] = 3
    hash[other_value_instance_one] = 4

    expect(hash[value_instance_one]).to eq(2)
    expect(hash[value_instance_two]).to eq(2)
    expect(hash[value_instance_three]).to eq(3)
    expect(hash[other_value_instance_one]).to eq(4)
  end

  it "is clonable" do
    instance = build(:value)
    cloned = instance.with(foo: 2)

    expect(instance.foo).to eq(1)
    expect(cloned.foo).to eq(2)
    expect(cloned.bar).to eq("2")
    expect(cloned.baz).to eq("3")

    expect do
      instance.with(foo: "1")
    end.to raise_error(Strict::InitializationError)
  end

  it "turns into a hash of attributes" do
    instance = build(:value)

    expect(instance.to_h).to eq(foo: 1, bar: "2", baz: "3")
  end

  it "deconstructs attributes for pattern matching" do
    instance = build(:value)

    expect(instance.deconstruct_keys(nil)).to eq(foo: 1, bar: "2", baz: "3")
    expect(instance.deconstruct_keys(%i[foo missing])).to eq(foo: 1)
  end

  it "can be inspected" do
    instance = build(:value)

    expect(instance.inspect).to eq("#<ValueClass foo=1 bar=\"2\" baz=\"3\">")
  end

  it "can be pretty printed" do
    instance = build(:value)
    output = StringIO.new
    PP.pp(instance, output, 5)

    expect(output.string).to eq(<<~OUTPUT)
      #<ValueClass
       foo=1
       bar="2"
       baz="3">
    OUTPUT
  end

  it "exposes a coercer" do
    instance = ValueClass.coercer.call(foo: 1, bar: "2", baz: "3")

    expect(instance).to be_an_instance_of(ValueClass)
    expect(instance.foo).to eq(1)
    expect(instance.bar).to eq("2")
    expect(instance.baz).to eq("3")

    instance = ValueClass.coercer.call("1")

    expect(instance).to eq("1")

    expect do
      ValueClass.coercer.call({})
    end.to raise_error(Strict::InitializationError)
  end
end
