# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Attributes::Class do
  it "aligns the constant with the lookup method" do
    configured_class = described_class
    mod = Module.new do
      const_set(configured_class::CONSTANT, "config value")

      extend configured_class
    end

    expect(mod.strict_attributes).to eq("config value")
  end
end
