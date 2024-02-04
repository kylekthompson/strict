# frozen_string_literal: true

require "test_helper"

describe Strict::Validators::Anything do
  describe "#===" do
    it "validates anything" do
      anything = Strict::Validators::Anything.instance

      assert_operator anything, :===, 1
      assert_operator anything, :===, true
      assert_operator anything, :===, {}
      assert_operator anything, :===, "something"
      assert_operator anything, :===, Strict
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      anything = Strict::Validators::Anything.instance

      assert_equal "Anything()", anything.to_s
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      anything = Strict::Validators::Anything.instance

      assert_equal "Anything()", anything.inspect
    end
  end
end
