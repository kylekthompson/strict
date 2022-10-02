# frozen_string_literal: true

module Strict
  module Matchers
    class HashOf
      attr_reader :key_matcher, :value_matcher

      def initialize(key_matcher, value_matcher)
        @key_matcher = key_matcher
        @value_matcher = value_matcher
      end

      def ===(value)
        Hash === value && value.all? do |k, v|
          key_matcher === k && value_matcher === v
        end
      end
    end
  end
end
