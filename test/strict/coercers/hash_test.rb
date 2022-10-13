# frozen_string_literal: true

require "test_helper"

describe Strict::Coercers::Hash do
  describe "#call" do
    it "returns nil when passed nil" do
      assert_nil Strict::Coercers::Hash.new(->(val) { val.to_s }, ->(val) { val + 1 }).call(nil)
    end

    it "returns the value when passed something that doesn't turn into a hash" do
      assert_equal "1", Strict::Coercers::Hash.new(->(val) { val.to_s }, ->(val) { val + 1 }).call("1")
    end

    it "returns the hash with the key and value coercers applied given a hash" do
      assert_equal(
        { "one" => 2, "two" => 3 },
        Strict::Coercers::Hash.new(->(val) { val.to_s }, ->(val) { val + 1 }).call({ one: 1, two: 2 })
      )
    end

    it "returns the hash with just a key coercer applied given a hash" do
      assert_equal(
        { "one" => 1, "two" => 2 },
        Strict::Coercers::Hash.new(->(val) { val.to_s }, nil).call({ one: 1, two: 2 })
      )
    end

    it "returns the hash with just a value coercer applied given a hash" do
      assert_equal(
        { one: 2, two: 3 },
        Strict::Coercers::Hash.new(nil, ->(val) { val + 1 }).call({ one: 1, two: 2 })
      )
    end

    it "returns the hash itself with no coercers" do
      assert_equal(
        { one: 1, two: 2 },
        Strict::Coercers::Hash.new(nil, nil).call([[:one, 1], [:two, 2]])
      )
    end
  end
end
