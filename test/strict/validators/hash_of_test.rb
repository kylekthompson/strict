# frozen_string_literal: true

require "test_helper"

describe Strict::Validators::HashOf do
  describe "#===" do
    before do
      @hash_of = Strict::Validators::HashOf.new(Integer, String)
    end

    it "validates the entries (both key and value) of the hash" do
      assert @hash_of === {}
      assert @hash_of === { 1 => "one" }
      assert @hash_of === { 1 => "one", 2 => "two" }
    end

    it "does not validate when a key does not validate" do
      refute @hash_of === { "one" => "one" }
      refute @hash_of === { 1 => "one", "two" => "two" }
    end

    it "does not validate when a value does not validate" do
      refute @hash_of === { 1 => 1 }
      refute @hash_of === { 1 => "one", 2 => 2 }
    end

    it "does not validate objects that are not hashes" do
      refute @hash_of === []
      refute @hash_of === [[1, "one"]]
    end
  end
end
