# frozen_string_literal: true

require "test_helper"

describe Strict::Validators::HashOf do
  describe "#===" do
    before do
      @hash_of = Strict::Validators::HashOf.new(Integer, String)
    end

    it "validates the entries (both key and value) of the hash" do
      assert_operator @hash_of, :===, {}
      assert_operator @hash_of, :===, { 1 => "one" }
      assert_operator @hash_of, :===, { 1 => "one", 2 => "two" }
    end

    it "does not validate when a key does not validate" do
      refute_operator @hash_of, :===, { "one" => "one" }
      refute_operator @hash_of, :===, { 1 => "one", "two" => "two" }
    end

    it "does not validate when a value does not validate" do
      refute_operator @hash_of, :===, { 1 => 1 }
      refute_operator @hash_of, :===, { 1 => "one", 2 => 2 }
    end

    it "does not validate objects that are not hashes" do
      refute_operator @hash_of, :===, []
      refute_operator @hash_of, :===, [[1, "one"]]
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      hash_of = Strict::Validators::HashOf.new("2", "3")

      assert_equal "HashOf(\"2\" => \"3\")", hash_of.to_s
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      hash_of = Strict::Validators::HashOf.new("2", "3")

      assert_equal "HashOf(\"2\" => \"3\")", hash_of.inspect
    end
  end
end
