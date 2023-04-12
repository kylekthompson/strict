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

    assert_equal 1, Strict.configuration.sample_ratio
    Strict.with_overrides(sample_ratio: 0) do
      current_random = Strict.configuration.random
      error = assert_raises(Strict::Error) do
        Strict.configure do |c|
          c.random = Random.new
        end
      end

      assert_equal current_random, Strict.configuration.random
      assert_match(/cannot reconfigure overridden configuration/, error.message)

      assert_equal 0, Strict.configuration.sample_ratio
      Strict.with_overrides(sample_ratio: 0.5) do
        assert_in_delta 0.5, Strict.configuration.sample_ratio
      end
      assert_equal 0, Strict.configuration.sample_ratio
    end
    assert_equal 1, Strict.configuration.sample_ratio
  end
end
