# frozen_string_literal: true

require "test_helper"

describe Strict::Validators::Anything do
  describe "#===" do
    it "validates anything" do
      anything = Strict::Validators::Anything.instance
      assert anything === 1
      assert anything === true
      assert anything === {}
      assert anything === "something"
      assert anything === Strict
    end
  end
end
