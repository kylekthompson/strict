# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Reader::Attributes do
  it "exposes the configuration on the class" do
    expect(ReaderClass.strict_attributes).to be_an_instance_of(Strict::Attributes::Configuration)
    expect(ReaderClass.strict_attributes.map(&:name)).to eq(%i[foo bar baz])
  end

  it "does not expose writer methods" do
    instance = build(:reader)

    expect do
      instance.foo = 1
    end.to raise_error(NoMethodError)
  end

  it "exposes reader methods" do
    instance = build(:reader)

    expect(instance.foo).to eq(1)
  end

  it "does not allow invalid arguments" do
    error = nil
    expect do
      ReaderClass.new(foo: "1", bar: "2", baz: "3")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("foo")
  end

  it "coerces arguments that can be coerced" do
    instance = build(:reader, bar: 2)

    expect(instance.bar).to eq("2")
  end

  it "does not require optional attributes" do
    instance = ReaderClass.new(foo: 1, bar: "2")

    expect(instance.baz).to eq("some string")
  end

  it "requires mandatory attributes" do
    error = nil
    expect do
      ReaderClass.new(foo: 1, baz: "3")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("bar")
  end

  it "does not allow additional attributes" do
    error = nil
    expect do
      ReaderClass.new(foo: 1, bar: "2", baz: "3", bat: "uh oh")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("bat")
  end

  it "aggregates errors" do
    error = nil
    expect do
      ReaderClass.new(foo: "1", baz: "3", bat: "uh oh")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("foo")
    expect(error.message).to include("bar")
    expect(error.message).to include("bat")
  end

  it "turns into a hash of attributes" do
    instance = build(:reader)

    expect(instance.to_h).to eq(foo: 1, bar: "2", baz: "3")
  end

  it "can be inspected" do
    instance = build(:reader)

    expect(instance.inspect).to eq("#<ReaderClass foo=1 bar=\"2\" baz=\"3\">")
  end

  it "can be pretty printed" do
    instance = build(:reader)
    output = StringIO.new
    PP.pp(instance, output, 5)

    expect(output.string).to eq(<<~OUTPUT)
      #<ReaderClass
       foo=1
       bar="2"
       baz="3">
    OUTPUT
  end

  it "exposes a coercer" do
    instance = ReaderClass.coercer.call(foo: 1, bar: "2", baz: "3")

    expect(instance).to be_an_instance_of(ReaderClass)
    expect(instance.foo).to eq(1)
    expect(instance.bar).to eq("2")
    expect(instance.baz).to eq("3")

    instance = ReaderClass.coercer.call("1")

    expect(instance).to eq("1")

    expect do
      ReaderClass.coercer.call({})
    end.to raise_error(Strict::InitializationError)
  end
end
