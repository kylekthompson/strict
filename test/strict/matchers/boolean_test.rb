# frozen_string_literal: true

require "test_helper"

describe Strict::Matchers::Boolean do
  describe "#===" do
    before do
      @boolean = Strict::Matchers::Boolean.instance
    end

    it "matches true" do
      assert @boolean === true
    end

    it "matches false" do
      assert @boolean === false
    end

    it "does not match objects that are not booleans" do
      refute @boolean === 1
      refute @boolean === "string"
    end
  end
end
