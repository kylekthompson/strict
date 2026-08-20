# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Validators::AllOf do
  describe "#===" do
    let(:value) { 1 }
    let(:validates) do
      Module.new.tap do |validator|
        validator.define_singleton_method(:===) do |value|
          value == 1
        end
      end
    end
    let(:invalidates) do
      Module.new.tap do |validator|
        validator.define_singleton_method(:===) do |value|
          value == 2
        end
      end
    end

    it "validates when all subvalidators validate" do
      all_of = described_class.new(validates, validates, validates)

      expect(all_of === value).to be(true)
    end

    it "does not validate when some subvalidators validate" do
      all_of = described_class.new(validates, invalidates, validates)

      expect(all_of === value).to be(false)
    end

    it "does not validate when no subvalidators validate" do
      all_of = described_class.new(invalidates, invalidates, invalidates)

      expect(all_of === value).to be(false)
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      all_of = described_class.new(1, "2", nil, Integer)

      expect(all_of.to_s).to eq("AllOf(1, \"2\", nil, Integer)")
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      all_of = described_class.new(1, "2", nil, Integer)

      expect(all_of.inspect).to eq("AllOf(1, \"2\", nil, Integer)")
    end
  end
end
