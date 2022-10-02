# frozen_string_literal: true

require "test_helper"

describe Strict::Matchers::RangeOf do
  describe "#===" do
    before do
      @range_of = Strict::Matchers::RangeOf.new(Integer)
    end

    it "matches ranges with elements that match the element matcher" do
      assert @range_of === (0..10)
    end

    it "matches endless ranges with elements that match the element matcher" do
      assert @range_of === (0..)
    end

    it "matches beginless ranges with elements that match the element matcher" do
      assert @range_of === (..10)
    end

    it "does not match ranges where the beginning does not match" do
      refute @range_of === (0.0..10)
    end

    it "does not match ranges where the end does not match" do
      refute @range_of === (0..10.0)
    end

    it "does not match ranges with elements that do not match the element matcher" do
      refute @range_of === ("a".."d")
    end

    it "does not match endless ranges with elements that do not match the element matcher" do
      refute @range_of === ("a"..)
    end

    it "does not match beginless ranges with elements that do not match the element matcher" do
      refute @range_of === (.."d")
    end

    it "does not match objects that are not ranges" do
      refute @range_of === [0, 1, 2, 3, 4]
    end
  end
end
