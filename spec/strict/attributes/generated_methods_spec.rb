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

  it "rejects generated readers that collide with existing or Strict methods" do
    %i[class to_h pretty_print inspect hash eql? initialize public_send].each do |name|
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
