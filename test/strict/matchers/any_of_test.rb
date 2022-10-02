# frozen_string_literal: true

require "test_helper"

describe Strict::Matchers::AnyOf do
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
      any_of = Strict::Matchers::AnyOf.new(@matches, @matches, @matches)
      assert any_of === @value
    end

    it "matches when some submatchers match" do
      any_of = Strict::Matchers::AnyOf.new(@matches, @mismatches, @matches)
      assert any_of === @value
    end

    it "does not match when no submatchers match" do
      any_of = Strict::Matchers::AnyOf.new(@mismatches, @mismatches, @mismatches)
      refute any_of === @value
    end
  end
end
