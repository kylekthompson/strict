# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Validators::Boolean do
  describe "#===" do
    let(:boolean) { described_class.instance }

    it "validates true" do
      expect(boolean === true).to be(true)
    end

    it "validates false" do
      expect(boolean === false).to be(true)
    end

    it "does not validate objects that are not booleans" do
      expect(boolean === 1).to be(false)
      expect(boolean === "string").to be(false)
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      boolean = described_class.instance

      expect(boolean.to_s).to eq("Boolean()")
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      boolean = described_class.instance

      expect(boolean.inspect).to eq("Boolean()")
    end
  end
end
