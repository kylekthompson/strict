# frozen_string_literal: true

require "test_helper"
require "securerandom"

describe Strict::Configuration do
  it "defaults to a sample_rate of 1" do
    configuration = Strict::Configuration.new

    assert_equal 1, configuration.sample_rate
  end

  it "defaults to a new instance of Random" do
    configuration_one = Strict::Configuration.new
    configuration_two = Strict::Configuration.new

    assert_instance_of Random, configuration_one.random
    assert_instance_of Random, configuration_two.random
    refute_equal configuration_two.random, configuration_one.random
  end

  describe "#sample_rate=" do
    it "ensures the rate is between 0 and 1" do
      configuration = Strict::Configuration.new

      configuration.sample_rate = 0

      assert_equal 0, configuration.sample_rate

      configuration.sample_rate = 1

      assert_equal 1, configuration.sample_rate

      configuration.sample_rate = 0.5

      assert_in_delta 0.5, configuration.sample_rate

      assert_raises Strict::Error do
        configuration.sample_rate = 1.1
      end

      assert_raises Strict::Error do
        configuration.sample_rate = -0.1
      end
    end
  end

  describe "#random=" do
    it "ensures it is a random formatter" do
      configuration = Strict::Configuration.new

      configuration.random = SecureRandom

      assert_equal SecureRandom, configuration.random

      random = Random.new(1)
      configuration.random = random

      assert_equal random, configuration.random

      assert_raises Strict::Error do
        configuration.random = 0
      end
    end
  end

  describe "#validate?" do
    it "is false when the sample rate is 0" do
      configuration = Strict::Configuration.new

      configuration.sample_rate = 0

      refute_predicate configuration, :validate?
    end

    it "is true when the sample rate is 1" do
      configuration = Strict::Configuration.new

      configuration.sample_rate = 1

      assert_predicate configuration, :validate?
    end

    it "is true roughly (sample_rate * 100)% of the time" do
      configuration = Strict::Configuration.new
      configuration.sample_rate = 0.25

      results = Hash.new { |h, k| h[k] = 0 }
      10_000.times do
        results[configuration.validate?] += 1
      end

      assert_in_delta 2500, results.fetch(true), 300
    end
  end

  describe "#to_h" do
    it "returns the attributes the comprise the configuration" do
      configuration = Strict::Configuration.new

      assert_equal(
        {
          random: configuration.random,
          sample_rate: configuration.sample_rate
        },
        configuration.to_h
      )
    end
  end
end
