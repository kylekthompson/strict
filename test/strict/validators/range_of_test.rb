# frozen_string_literal: true

require "test_helper"

describe Strict::Validators::RangeOf do
  describe "#===" do
    before do
      @range_of = Strict::Validators::RangeOf.new(Integer)
    end

    it "validates ranges with elements that validate the element validator" do
      assert @range_of === (0..10)
    end

    it "validates endless ranges with elements that validate the element validator" do
      assert @range_of === (0..)
    end

    it "validates beginless ranges with elements that validate the element validator" do
      assert @range_of === (..10)
    end

    it "does not validate ranges where the beginning does not validate" do
      refute @range_of === (0.0..10)
    end

    it "does not validate ranges where the end does not validate" do
      refute @range_of === (0..10.0)
    end

    it "does not validate ranges with elements that do not validate the element validator" do
      refute @range_of === ("a".."d")
    end

    it "does not validate endless ranges with elements that do not validate the element validator" do
      refute @range_of === ("a"..)
    end

    it "does not validate beginless ranges with elements that do not validate the element validator" do
      refute @range_of === (.."d")
    end

    it "does not validate objects that are not ranges" do
      refute @range_of === [0, 1, 2, 3, 4]
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      range_of = Strict::Validators::RangeOf.new("2")
      assert_equal "RangeOf(\"2\")", range_of.to_s
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      range_of = Strict::Validators::RangeOf.new("2")
      assert_equal "RangeOf(\"2\")", range_of.inspect
    end
  end
end
