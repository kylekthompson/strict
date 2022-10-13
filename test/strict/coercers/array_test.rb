# frozen_string_literal: true

require "test_helper"

describe Strict::Coercers::Array do
  describe "#call" do
    it "returns nil when passed nil" do
      assert_nil Strict::Coercers::Array.new(->(val) { val + 1 }).call(nil)
    end

    it "returns the value when passed something that doesn't turn into an array" do
      assert_equal "1", Strict::Coercers::Array.new(->(val) { val + 1 }).call("1")
    end

    it "returns the array with the element coercer applied given an array" do
      assert_equal [2, 3, 4], Strict::Coercers::Array.new(->(val) { val + 1 }).call([1, 2, 3])
    end

    it "returns the array itself with no element coercer" do
      assert_equal [[:one, 1], [:two, 2]], Strict::Coercers::Array.new(nil).call({ one: 1, two: 2 })
    end
  end
end
