# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Attributes::GeneratedMethods do
  it "owns generated methods for values and objects" do
    value_class = Class.new do
      include Strict::Value

      attributes { name String }
    end
    object_class = Class.new do
      include Strict::Object

      attributes { name String }
    end
    value_owner = value_class.instance_method(:name).owner
    object_owner = object_class.instance_method(:name).owner

    expect(value_owner).to be_a(described_class)
    expect(object_owner).to be_a(described_class)
    expect(object_class.instance_method(:name=).owner).to be(object_owner)
  end

  it "rejects a second attributes block on the same class" do
    [Strict::Value, Strict::Object].each do |capability|
      strict_class = Class.new do
        include capability

        attributes { nil }
      end

      expect do
        strict_class.attributes { name String }
      end.to raise_error(ArgumentError)
    end
  end

  it "rejects redefined attributes that collide with subclass methods" do
    parent_class = Class.new do
      include Strict::Value

      attributes { name String }
    end

    expect do
      Class.new(parent_class) do
        def name = "subclass method"

        attributes { name Integer }
      end
    end.to raise_error(ArgumentError)
  end

  it "allows generated readers to override inherited methods" do
    parent_class = Class.new do
      def tag(*) = "inherited tag"

      def theme = "inherited theme"
      protected :theme
    end
    value_class = Class.new(parent_class) do
      include Strict::Value

      attributes do
        tag AnyOf("h1", "h2")
        theme String
        strict_attribute :format, String
        strict_attribute :system, String
        strict_attribute :fork, String
      end
    end
    value = value_class.new(tag: "h1", theme: "dark", format: "short", system: "metric", fork: "main")

    expect(value.to_h).to eq(tag: "h1", theme: "dark", format: "short", system: "metric", fork: "main")
    expect(value).to respond_to(:theme, :format, :system, :fork)
    expect do
      value_class.new(tag: "div", theme: "dark", format: "short", system: "metric", fork: "main")
    end.to raise_error(Strict::InitializationError)
  end

  it "allows generated accessors to override inherited methods" do
    parent_class = Class.new do
      attr_accessor :status
      private :status=
    end
    object_class = Class.new(parent_class) do
      include Strict::Object

      attributes { status String }
    end
    object = object_class.new(status: "pending")

    object.status = "complete"

    expect(object.status).to eq("complete")
    expect do
      object.status = :invalid
    end.to raise_error(Strict::AssignmentError)
  end

  it "rejects generated readers that collide with existing or Strict methods" do
    %i[
      __send__ class deconstruct_keys eql? hash initialize instance_variable_set inspect method_missing
      pretty_print public_send raise to_h with
    ].each do |name|
      expect do
        Class.new do
          include Strict::Value

          attributes { strict_attribute name, String }
        end
      end.to raise_error(ArgumentError)
    end
  end

  it "checks public, protected, and private reader collisions" do
    %i[public_reader protected_reader private_reader].each do |name|
      visibility = name.to_s.delete_suffix("_reader").to_sym

      expect do
        Class.new do
          include Strict::Object

          define_method(name) { nil }
          send(visibility, name)
          attributes { strict_attribute name, String }
        end
      end.to raise_error(ArgumentError)
    end
  end

  it "rejects generated object writers that collide with existing methods" do
    expect do
      Class.new do
        include Strict::Object

        def name=(_value); end
        private :name=

        attributes { name String }
      end
    end.to raise_error(ArgumentError)
  end
end
