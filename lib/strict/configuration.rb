# frozen_string_literal: true

module Strict
  class Configuration
    attr_reader :random, :sample_rate

    def initialize(random: nil, sample_rate: nil)
      self.random = random || Random.new
      self.sample_rate = sample_rate || 1
    end

    def random=(random)
      case random
      when Random::Formatter
        @random = random
      else
        raise Strict::Error, "Expected a Random::Formatter, got: #{random.inspect}."
      end
    end

    def sample_rate=(rate)
      case rate
      when 0..1
        @sample_rate = rate
      else
        raise Strict::Error, "Expected a sample rate between 0 and 1 (inclusive), got: #{rate.inspect}. " \
                             "A rate of 0 will disable strict validation. " \
                             "A rate of 1 will validate 100% of the time. " \
                             "A rate of 0.25 will validate roughly 25% of the time."
      end
    end

    def validate?
      sample_rate >= 1 || (sample_rate > 0 && random.rand < sample_rate) # rubocop:disable Style/NumericPredicate
    end

    def to_h
      {
        random: random,
        sample_rate: sample_rate
      }
    end
  end
end
