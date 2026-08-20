# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Coercers::Array do
  describe "#call" do
    it "returns nil when passed nil" do
      expect(described_class.new(->(val) { val + 1 }).call(nil)).to be_nil
    end

    it "returns the value when passed something that doesn't turn into an array" do
      expect(described_class.new(->(val) { val + 1 }).call("1")).to eq("1")
    end

    it "returns the array with the element coercer applied given an array" do
      expect(described_class.new(->(val) { val + 1 }).call([1, 2, 3])).to eq([2, 3, 4])
    end

    it "returns the array itself with no element coercer" do
      expect(described_class.new(nil).call({ one: 1, two: 2 })).to eq([[:one, 1], [:two, 2]])
    end
  end
end
