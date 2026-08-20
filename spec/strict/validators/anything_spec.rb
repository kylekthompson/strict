# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Validators::Anything do
  describe "#===" do
    it "validates anything" do
      anything = described_class.instance

      expect(anything === 1).to be(true)
      expect(anything === true).to be(true)
      expect(anything === {}).to be(true)
      expect(anything === "something").to be(true)
      expect(anything === Strict).to be(true)
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      anything = described_class.instance

      expect(anything.to_s).to eq("Anything()")
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      anything = described_class.instance

      expect(anything.inspect).to eq("Anything()")
    end
  end
end
