# frozen_string_literal: true

require "spec_helper"
require "securerandom"

RSpec.describe Strict::Configuration do
  it "defaults to a sample_rate of 1" do
    configuration = described_class.new

    expect(configuration.sample_rate).to eq(1)
  end

  it "defaults to a new instance of Random" do
    configuration_one = described_class.new
    configuration_two = described_class.new

    expect(configuration_one.random).to be_an_instance_of(Random)
    expect(configuration_two.random).to be_an_instance_of(Random)
    expect(configuration_one.random).not_to eq(configuration_two.random)
  end

  describe "#sample_rate=" do
    it "ensures the rate is between 0 and 1" do
      configuration = described_class.new

      configuration.sample_rate = 0

      expect(configuration.sample_rate).to eq(0)

      configuration.sample_rate = 1

      expect(configuration.sample_rate).to eq(1)

      configuration.sample_rate = 0.5

      expect(configuration.sample_rate).to be_within(0.001).of(0.5)

      expect do
        configuration.sample_rate = 1.1
      end.to raise_error(Strict::Error)

      expect do
        configuration.sample_rate = -0.1
      end.to raise_error(Strict::Error)
    end
  end

  describe "#random=" do
    it "ensures it is a random formatter" do
      configuration = described_class.new

      configuration.random = SecureRandom

      expect(configuration.random).to eq(SecureRandom)

      random = Random.new(1)
      configuration.random = random

      expect(configuration.random).to be(random)

      expect do
        configuration.random = 0
      end.to raise_error(Strict::Error)
    end
  end

  describe "#validate?" do
    it "is false when the sample rate is 0" do
      configuration = described_class.new

      configuration.sample_rate = 0

      expect(configuration.validate?).to be(false)
    end

    it "is true when the sample rate is 1" do
      configuration = described_class.new

      configuration.sample_rate = 1

      expect(configuration.validate?).to be(true)
    end

    it "is true roughly (sample_rate * 100)% of the time" do
      configuration = described_class.new
      configuration.sample_rate = 0.25

      results = Hash.new { |h, k| h[k] = 0 }
      10_000.times do
        results[configuration.validate?] += 1
      end

      expect(results.fetch(true)).to be_within(300).of(2500)
    end
  end

  describe "#to_h" do
    it "returns the attributes the comprise the configuration" do
      configuration = described_class.new

      expect(configuration.to_h).to eq(
        {
          random: configuration.random,
          sample_rate: configuration.sample_rate
        }
      )
    end
  end
end
