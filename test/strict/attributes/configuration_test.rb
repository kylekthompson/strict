# frozen_string_literal: true

require "test_helper"

describe Strict::Attributes::Configuration do
  it "enumerates" do
    configuration = Strict::Attributes::Configuration.new(
      attributes: [Strict::Attribute.make(:foo), Strict::Attribute.make(:bar)]
    )

    assert_equal 2, configuration.count
    assert_equal %i[foo bar], configuration.map(&:name)
  end

  describe "#named!" do
    it "returns the attribute of the provided name" do
      configuration = Strict::Attributes::Configuration.new(
        attributes: [Strict::Attribute.make(:foo), Strict::Attribute.make(:bar)]
      )

      attribute = configuration.named!(:bar)
      assert_equal :bar, attribute.name
    end

    it "raises on unknown attributes" do
      configuration = Strict::Attributes::Configuration.new(
        attributes: [Strict::Attribute.make(:foo), Strict::Attribute.make(:bar)]
      )

      assert_raises(Strict::Attributes::Configuration::UnknownAttributeError) do
        configuration.named!(:unknown)
      end
    end
  end
end
