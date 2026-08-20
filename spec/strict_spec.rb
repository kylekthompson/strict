# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict do
  it "has a version number" do
    expect(Strict::VERSION).not_to be_nil
  end

  it "can be configured" do
    expect(described_class.configuration).not_to be_nil
    original_random = described_class.configuration.random

    described_class.configure do |c|
      c.random = Random.new
    end

    expect(described_class.configuration.random).not_to eq(original_random)

    expect(described_class.configuration.sample_rate).to eq(1)
    described_class.with_overrides(sample_rate: 0) do
      current_random = described_class.configuration.random
      expect do
        described_class.configure do |c|
          c.random = Random.new
        end
      end.to raise_error(Strict::Error, /cannot reconfigure overridden configuration/)

      expect(described_class.configuration.random).to be(current_random)

      expect(described_class.configuration.sample_rate).to eq(0)
      described_class.with_overrides(sample_rate: 0.5) do
        expect(described_class.configuration.sample_rate).to be_within(0.001).of(0.5)
      end
      expect(described_class.configuration.sample_rate).to eq(0)
    end
    expect(described_class.configuration.sample_rate).to eq(1)
  end

  it "does not expose implementation constants through consumer classes" do
    value_class = Class.new do
      include Strict::Value

      attributes { nil }
    end
    object_class = Class.new do
      include Strict::Object

      attributes { nil }
    end
    method_class = Class.new { include Strict::Method }
    interface_class = Class.new { include Strict::Interface }
    union_class = Class.new { include Strict::Union }

    expect(value_class.constants).not_to include(:STRICT_INTERNAL_ATTRIBUTES_CONFIGURATION__)
    expect(object_class.constants).not_to include(:STRICT_INTERNAL_ATTRIBUTES_CONFIGURATION__)
    expect(method_class.constants).not_to include(:ClassMethods)
    expect(interface_class.constants).not_to include(:ClassMethods)
    expect(union_class.constants).not_to include(:ClassMethods, :Instance)
  end

  it "does not reserve a configuration constant on value and object classes" do
    [Strict::Value, Strict::Object].each do |capability|
      strict_class = Class.new do
        const_set(:STRICT_INTERNAL_ATTRIBUTES_CONFIGURATION__, :application_value)
        include capability

        attributes { name String }
      end

      expect(strict_class.const_get(:STRICT_INTERNAL_ATTRIBUTES_CONFIGURATION__, false)).to eq(:application_value)
      expect(strict_class.new(name: "example").name).to eq("example")
    end
  end
end
