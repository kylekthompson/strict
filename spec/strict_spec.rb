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
end
