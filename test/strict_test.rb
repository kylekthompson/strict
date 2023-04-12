# frozen_string_literal: true

require "test_helper"

describe Strict do
  it "has a version number" do
    refute_nil Strict::VERSION
  end

  it "can be configured" do
    refute_nil Strict.configuration
    original_random = Strict.configuration.random

    Strict.configure do |c|
      c.random = Random.new
    end

    refute_equal original_random, Strict.configuration.random

    assert_equal 1, Strict.configuration.sample_rate
    Strict.with_overrides(sample_rate: 0) do
      current_random = Strict.configuration.random
      error = assert_raises(Strict::Error) do
        Strict.configure do |c|
          c.random = Random.new
        end
      end

      assert_equal current_random, Strict.configuration.random
      assert_match(/cannot reconfigure overridden configuration/, error.message)

      assert_equal 0, Strict.configuration.sample_rate
      Strict.with_overrides(sample_rate: 0.5) do
        assert_in_delta 0.5, Strict.configuration.sample_rate
      end
      assert_equal 0, Strict.configuration.sample_rate
    end
    assert_equal 1, Strict.configuration.sample_rate
  end
end
