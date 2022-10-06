# frozen_string_literal: true

require "test_helper"

describe Strict::Attributes::Configured do
  it "aligns the constant with the lookup method" do
    mod = Module.new do
      const_set(Strict::Attributes::Configured::CONSTANT, "config value")

      extend Strict::Attributes::Configured
    end

    assert_equal "config value", mod.strict_attributes
  end
end
