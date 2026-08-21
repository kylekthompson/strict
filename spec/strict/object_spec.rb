# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Object do
  it "exposes the configuration on the class" do
    expect(ObjectClass.strict_attributes).to be_an_instance_of(Strict::Attributes::Configuration)
    expect(ObjectClass.strict_attributes.map(&:name)).to eq(%i[foo bar baz])
  end

  it "combines inherited and subclass attributes with writers" do
    parent_class = Class.new do
      include Strict::Object

      attributes do
        name String
      end
    end
    child_class = Class.new(parent_class) do
      attributes do
        employee_id String
      end
    end
    employee = child_class.new(name: "Ada", employee_id: "employee_123")

    employee.name = "Grace"
    employee.employee_id = "employee_456"

    expect(employee.to_h).to eq(name: "Grace", employee_id: "employee_456")
    expect(parent_class.strict_attributes.map(&:name)).to eq([:name])
  end

  it "uses redefined attributes for subclass assignment without changing the parent" do
    parent_class = Class.new do
      include Strict::Object

      attributes { value String }
    end
    child_class = Class.new(parent_class) do
      attributes { value Integer }
    end
    parent = parent_class.new(value: "parent")
    child = child_class.new(value: 1)

    parent.value = "updated parent"
    child.value = 2

    expect(parent.value).to eq("updated parent")
    expect(child.value).to eq(2)
    expect do
      child.value = "invalid"
    end.to raise_error(Strict::AssignmentError)
  end

  it "exposes writer methods" do
    instance = build(:strict_object)
    instance.foo = 2

    expect(instance.foo).to eq(2)
  end

  it "exposes reader methods" do
    instance = build(:strict_object)

    expect(instance.foo).to eq(1)
  end

  it "does not allow invalid arguments at initialization" do
    error = nil
    expect do
      ObjectClass.new(foo: "1", bar: "2", baz: "3")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("foo")
  end

  it "coerces arguments that can be coerced at initialization" do
    instance = build(:strict_object, bar: 2)

    expect(instance.bar).to eq("2")
  end

  it "does not require optional attributes at initialization" do
    instance = ObjectClass.new(foo: 1, bar: "2")

    expect(instance.baz).to eq("some string")
  end

  it "requires mandatory attributes at initialization" do
    error = nil
    expect do
      ObjectClass.new(foo: 1, baz: "3")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("bar")
  end

  it "does not allow additional attributes at initialization" do
    error = nil
    expect do
      ObjectClass.new(foo: 1, bar: "2", baz: "3", bat: "uh oh")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("bat")
  end

  it "aggregates errors at initialization" do
    error = nil
    expect do
      ObjectClass.new(foo: "1", baz: "3", bat: "uh oh")
    end.to raise_error(Strict::InitializationError) { |raised_error| error = raised_error }

    expect(error.message).to include("foo")
    expect(error.message).to include("bar")
    expect(error.message).to include("bat")
  end

  it "does not allow invalid arguments at assignment" do
    instance = build(:strict_object)

    error = nil
    expect do
      instance.foo = "1"
    end.to raise_error(Strict::AssignmentError) { |raised_error| error = raised_error }

    expect(error.message).to include("foo")
  end

  it "coerces arguments that can be coerced at assignment" do
    instance = build(:strict_object)
    instance.bar = 3

    expect(instance.bar).to eq("3")
  end

  it "turns into a hash of attributes" do
    instance = build(:strict_object)

    expect(instance.to_h).to eq(foo: 1, bar: "2", baz: "3")
  end

  it "can be inspected" do
    instance = build(:strict_object)

    expect(instance.inspect).to eq("#<ObjectClass foo=1 bar=\"2\" baz=\"3\">")
  end

  it "can be pretty printed" do
    instance = build(:strict_object)
    output = StringIO.new
    PP.pp(instance, output, 5)

    expect(output.string).to eq(<<~OUTPUT)
      #<ObjectClass
       foo=1
       bar="2"
       baz="3">
    OUTPUT
  end

  it "exposes a coercer" do
    instance = ObjectClass.coercer.call(foo: 1, bar: "2", baz: "3")

    expect(instance).to be_an_instance_of(ObjectClass)
    expect(instance.foo).to eq(1)
    expect(instance.bar).to eq("2")
    expect(instance.baz).to eq("3")

    instance = ObjectClass.coercer.call("1")

    expect(instance).to eq("1")

    expect do
      ObjectClass.coercer.call({})
    end.to raise_error(Strict::InitializationError)
  end

  it "returns an exact instance unchanged from its coercer" do
    instance = build(:strict_object)

    expect(ObjectClass.coercer.call(instance)).to be(instance)
  end

  it "converts subclass instances into new instances of the coercer's exact class" do
    person_class = Class.new do
      include Strict::Object

      attributes do
        name String
      end
    end
    employee_class = Class.new(person_class) do
      attributes do
        employee_id String
      end
    end
    employee = employee_class.new(name: "Ada", employee_id: "employee_123")

    coerced = person_class.coercer.call(employee)

    expect(coerced).to be_an_instance_of(person_class)
    expect(coerced).not_to be(employee)
    expect(coerced.to_h).to eq(name: "Ada")
  end

  it "supports predicate and bang attribute names" do
    object_class = Class.new do
      include Strict::Object

      attributes do
        active? Strict::Validators::Boolean.instance
        dangerous! Strict::Validators::Boolean.instance
      end
    end
    instance = object_class.new(active?: true, dangerous!: false)

    instance.public_send(:"active?=", false)
    instance.public_send(:"dangerous!=", true)

    expect(instance.active?).to be(false)
    expect(instance.dangerous!).to be(true)
    expect(instance.to_h).to eq(active?: false, dangerous!: true)
  end
end
