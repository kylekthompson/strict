# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Validators::AnyOf do
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
      any_of = described_class.new(validates, validates, validates)

      expect(any_of === value).to be(true)
    end

    it "validates when some subvalidators validate" do
      any_of = described_class.new(validates, invalidates, validates)

      expect(any_of === value).to be(true)
    end

    it "does not validate when no subvalidators validate" do
      any_of = described_class.new(invalidates, invalidates, invalidates)

      expect(any_of === value).to be(false)
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      any_of = described_class.new(1, "2", nil, Integer)

      expect(any_of.to_s).to eq("AnyOf(1, \"2\", nil, Integer)")
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      any_of = described_class.new(1, "2", nil, Integer)

      expect(any_of.inspect).to eq("AnyOf(1, \"2\", nil, Integer)")
    end
  end
end
