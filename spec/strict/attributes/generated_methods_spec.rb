# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Attributes::GeneratedMethods do
  it "owns generated methods and their configurations for values and objects" do
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
    expect(value_owner.const_get(Strict::Attributes::Class::CONSTANT, false)).to be(value_class.strict_attributes)
    expect(object_owner.const_get(Strict::Attributes::Class::CONSTANT, false)).to be(object_class.strict_attributes)
  end
end
