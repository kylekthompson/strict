# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Attributes::Class do
  it "builds a coercer for the extended class" do
    attributes_class = Class.new
    attributes_class.extend(described_class)
    coercer = attributes_class.coercer

    expect(coercer).to be_a(Strict::Attributes::Coercer)
    expect(coercer.attributes_class).to be(attributes_class)
  end
end
