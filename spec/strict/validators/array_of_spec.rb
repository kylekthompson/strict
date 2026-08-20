# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Validators::ArrayOf do
  describe "#===" do
    let(:array_of) { described_class.new(Integer) }

    it "validates arrays with all elements validateing the validator" do
      expect(array_of === []).to be(true)
      expect(array_of === [1]).to be(true)
      expect(array_of === [1, 2]).to be(true)
    end

    it "does not validate arrays when elements do not validate the validator" do
      expect(array_of === [""]).to be(false)
      expect(array_of === [1, ""]).to be(false)
      expect(array_of === ["", 1]).to be(false)
    end

    it "does not validate objects which are not arrays" do
      expect(array_of === (0..10)).to be(false)
    end
  end

  describe "#coercer" do
    it "coerces array-like values and their elements" do
      element_validator = Object.new
      element_validator.define_singleton_method(:coercer) { ->(value) { value.to_s } }
      array_of = described_class.new(element_validator)

      expect(array_of.coercer.call(1..3)).to eq(%w[1 2 3])
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      array_of = described_class.new("2")

      expect(array_of.to_s).to eq("ArrayOf(\"2\")")
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      array_of = described_class.new("2")

      expect(array_of.inspect).to eq("ArrayOf(\"2\")")
    end
  end
end
