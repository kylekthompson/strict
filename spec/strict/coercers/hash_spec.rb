# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Coercers::Hash do
  describe "#call" do
    it "returns nil when passed nil" do
      expect(described_class.new(->(val) { val.to_s }, ->(val) { val + 1 }).call(nil)).to be_nil
    end

    it "returns the value when passed something that doesn't turn into a hash" do
      expect(described_class.new(->(val) { val.to_s }, ->(val) { val + 1 }).call("1")).to eq("1")
    end

    it "returns the hash with the key and value coercers applied given a hash" do
      result = described_class.new(->(val) { val.to_s }, ->(val) { val + 1 }).call({ one: 1, two: 2 })

      expect(result).to eq({ "one" => 2, "two" => 3 })
    end

    it "returns the hash with just a key coercer applied given a hash" do
      result = described_class.new(->(val) { val.to_s }, nil).call({ one: 1, two: 2 })

      expect(result).to eq({ "one" => 1, "two" => 2 })
    end

    it "returns the hash with just a value coercer applied given a hash" do
      result = described_class.new(nil, ->(val) { val + 1 }).call({ one: 1, two: 2 })

      expect(result).to eq({ one: 2, two: 3 })
    end

    it "returns the hash itself with no coercers" do
      result = described_class.new(nil, nil).call([[:one, 1], [:two, 2]])

      expect(result).to eq({ one: 1, two: 2 })
    end
  end
end
