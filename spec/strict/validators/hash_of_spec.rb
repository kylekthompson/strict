# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Validators::HashOf do
  describe "#===" do
    let(:hash_of) { described_class.new(Integer, String) }

    it "validates the entries (both key and value) of the hash" do
      expect(hash_of === {}).to be(true)
      expect(hash_of === { 1 => "one" }).to be(true)
      expect(hash_of === { 1 => "one", 2 => "two" }).to be(true)
    end

    it "does not validate when a key does not validate" do
      expect(hash_of === { "one" => "one" }).to be(false)
      expect(hash_of === { 1 => "one", "two" => "two" }).to be(false)
    end

    it "does not validate when a value does not validate" do
      expect(hash_of === { 1 => 1 }).to be(false)
      expect(hash_of === { 1 => "one", 2 => 2 }).to be(false)
    end

    it "does not validate objects that are not hashes" do
      expect(hash_of === []).to be(false)
      expect(hash_of === [[1, "one"]]).to be(false)
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      hash_of = described_class.new("2", "3")

      expect(hash_of.to_s).to eq("HashOf(\"2\" => \"3\")")
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      hash_of = described_class.new("2", "3")

      expect(hash_of.inspect).to eq("HashOf(\"2\" => \"3\")")
    end
  end
end
