# frozen_string_literal: true

module Strict
  class Configuration
    attr_reader :random, :sample_ratio

    def initialize
      self.random = Random.new
      self.sample_ratio = 1
    end

    def random=(random)
      case random
      when Random::Formatter
        @random = random
      else
        raise Strict::Error, "Expected a Random::Formatter, got: #{random.inspect}."
      end
    end

    def sample_ratio=(ratio)
      case ratio
      when 0..1
        @sample_ratio = ratio
      else
        raise Strict::Error, "Expected a sample ratio between 0 and 1 (inclusive), got: #{ratio.inspect}. " \
                             "A ratio of 0 will disable strict validation. " \
                             "A ratio of 1 will validate 100% of the time. " \
                             "A ratio of 0.25 will validate roughly 25% of the time."
      end
    end

    def validate?
      sample_ratio >= 1 || (sample_ratio > 0 && random.rand < sample_ratio) # rubocop:disable Style/NumericPredicate
    end
  end
end
