# frozen_string_literal: true

require "test_helper"

describe Strict::Matchers::ArrayOf do
  describe "#===" do
    before do
      @array_of = Strict::Matchers::ArrayOf.new(Integer)
    end

    it "matches arrays with all elements matching the matcher" do
      assert @array_of === []
      assert @array_of === [1]
      assert @array_of === [1, 2]
    end

    it "does not match arrays when elements do not match the matcher" do
      refute @array_of === [""]
      refute @array_of === [1, ""]
      refute @array_of === ["", 1]
    end

    it "does not match objects which are not arrays" do
      refute @array_of === (0..10)
    end
  end
end
