# frozen_string_literal: true

require "test_helper"

describe Strict::Validators::Boolean do
  describe "#===" do
    before do
      @boolean = Strict::Validators::Boolean.instance
    end

    it "validates true" do
      assert_operator @boolean, :===, true
    end

    it "validates false" do
      assert_operator @boolean, :===, false
    end

    it "does not validate objects that are not booleans" do
      refute_operator @boolean, :===, 1
      refute_operator @boolean, :===, "string"
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      boolean = Strict::Validators::Boolean.instance

      assert_equal "Boolean()", boolean.to_s
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      boolean = Strict::Validators::Boolean.instance

      assert_equal "Boolean()", boolean.inspect
    end
  end
end
