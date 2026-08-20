# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Attributes::Configuration do
  it "enumerates" do
    configuration = described_class.new(
      attributes: [Strict::Attribute.make(:foo), Strict::Attribute.make(:bar)]
    )

    expect(configuration.count).to eq(2)
    expect(configuration.map(&:name)).to eq(%i[foo bar])
  end

  describe "#named!" do
    it "returns the attribute of the provided name" do
      configuration = described_class.new(
        attributes: [Strict::Attribute.make(:foo), Strict::Attribute.make(:bar)]
      )

      attribute = configuration.named!(:bar)

      expect(attribute.name).to eq(:bar)
    end

    it "raises on unknown attributes" do
      configuration = described_class.new(
        attributes: [Strict::Attribute.make(:foo), Strict::Attribute.make(:bar)]
      )

      expect do
        configuration.named!(:unknown)
      end.to raise_error(Strict::Attributes::Configuration::UnknownAttributeError)
    end
  end
end
