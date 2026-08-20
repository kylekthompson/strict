# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Validators::RangeOf do
  describe "#===" do
    let(:range_of) { described_class.new(Integer) }

    it "validates ranges with elements that validate the element validator" do
      expect(range_of === (0..10)).to be(true)
    end

    it "validates endless ranges with elements that validate the element validator" do
      expect(range_of === (0..)).to be(true)
    end

    it "validates beginless ranges with elements that validate the element validator" do
      expect(range_of === (..10)).to be(true)
    end

    it "does not validate ranges where the beginning does not validate" do
      expect(range_of === (0.0..10)).to be(false)
    end

    it "does not validate ranges where the end does not validate" do
      expect(range_of === (0..10.0)).to be(false)
    end

    it "does not validate ranges with elements that do not validate the element validator" do
      expect(range_of === ("a".."d")).to be(false)
    end

    it "does not validate endless ranges with elements that do not validate the element validator" do
      expect(range_of === ("a"..)).to be(false)
    end

    it "does not validate beginless ranges with elements that do not validate the element validator" do
      expect(range_of === (.."d")).to be(false)
    end

    it "does not validate objects that are not ranges" do
      expect(range_of === [0, 1, 2, 3, 4]).to be(false)
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      range_of = described_class.new("2")

      expect(range_of.to_s).to eq("RangeOf(\"2\")")
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      range_of = described_class.new("2")

      expect(range_of.inspect).to eq("RangeOf(\"2\")")
    end
  end
end
