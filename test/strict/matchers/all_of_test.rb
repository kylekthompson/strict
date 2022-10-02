# frozen_string_literal: true

require "test_helper"

describe Strict::Matchers::AllOf do
  describe "#===" do
    before do
      @value = 1
      @matches = Module.new do
        def self.===(value)
          value == 1
        end
      end
      @mismatches = Module.new do
        def self.===(value)
          value == 2
        end
      end
    end

    it "matches when all submatchers match" do
      all_of = Strict::Matchers::AllOf.new(@matches, @matches, @matches)
      assert all_of === @value
    end

    it "does not match when some submatchers match" do
      all_of = Strict::Matchers::AllOf.new(@matches, @mismatches, @matches)
      refute all_of === @value
    end

    it "does not match when no submatchers match" do
      all_of = Strict::Matchers::AllOf.new(@mismatches, @mismatches, @mismatches)
      refute all_of === @value
    end
  end
end
