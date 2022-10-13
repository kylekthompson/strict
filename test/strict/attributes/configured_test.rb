# frozen_string_literal: true

require "test_helper"

describe Strict::Attributes::Class do
  it "aligns the constant with the lookup method" do
    mod = Module.new do
      const_set(Strict::Attributes::Class::CONSTANT, "config value")

      extend Strict::Attributes::Class
    end

    assert_equal "config value", mod.strict_attributes
  end
end
