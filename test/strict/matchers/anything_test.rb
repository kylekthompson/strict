# frozen_string_literal: true

require "test_helper"

describe Strict::Matchers::Anything do
  describe "#===" do
    it "matches anything" do
      anything = Strict::Matchers::Anything.instance
      assert anything === 1
      assert anything === true
      assert anything === {}
      assert anything === "something"
      assert anything === Strict
    end
  end
end
