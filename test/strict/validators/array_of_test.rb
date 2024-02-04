# frozen_string_literal: true

require "test_helper"

describe Strict::Validators::ArrayOf do
  describe "#===" do
    before do
      @array_of = Strict::Validators::ArrayOf.new(Integer)
    end

    it "validates arrays with all elements validateing the validator" do
      assert_operator @array_of, :===, []
      assert_operator @array_of, :===, [1]
      assert_operator @array_of, :===, [1, 2]
    end

    it "does not validate arrays when elements do not validate the validator" do
      refute_operator @array_of, :===, [""]
      refute_operator @array_of, :===, [1, ""]
      refute_operator @array_of, :===, ["", 1]
    end

    it "does not validate objects which are not arrays" do
      refute_operator @array_of, :===, (0..10)
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      array_of = Strict::Validators::ArrayOf.new("2")

      assert_equal "ArrayOf(\"2\")", array_of.to_s
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      array_of = Strict::Validators::ArrayOf.new("2")

      assert_equal "ArrayOf(\"2\")", array_of.inspect
    end
  end
end
