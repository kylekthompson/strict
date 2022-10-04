# frozen_string_literal: true

require "test_helper"

describe Strict::Validators::ArrayOf do
  describe "#===" do
    before do
      @array_of = Strict::Validators::ArrayOf.new(Integer)
    end

    it "validates arrays with all elements validateing the validator" do
      assert @array_of === []
      assert @array_of === [1]
      assert @array_of === [1, 2]
    end

    it "does not validate arrays when elements do not validate the validator" do
      refute @array_of === [""]
      refute @array_of === [1, ""]
      refute @array_of === ["", 1]
    end

    it "does not validate objects which are not arrays" do
      refute @array_of === (0..10)
    end
  end
end
