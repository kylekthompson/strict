# frozen_string_literal: true

require "test_helper"

describe Strict::Validators::AllOf do
  describe "#===" do
    before do
      @value = 1
      @validates = Module.new do
        def self.===(value)
          value == 1
        end
      end
      @invalidates = Module.new do
        def self.===(value)
          value == 2
        end
      end
    end

    it "validates when all subvalidators validate" do
      all_of = Strict::Validators::AllOf.new(@validates, @validates, @validates)
      assert all_of === @value
    end

    it "does not validate when some subvalidators validate" do
      all_of = Strict::Validators::AllOf.new(@validates, @invalidates, @validates)
      refute all_of === @value
    end

    it "does not validate when no subvalidators validate" do
      all_of = Strict::Validators::AllOf.new(@invalidates, @invalidates, @invalidates)
      refute all_of === @value
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      all_of = Strict::Validators::AllOf.new(1, "2", nil, Integer)
      assert_equal "AllOf(1, \"2\", nil, Integer)", all_of.to_s
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      all_of = Strict::Validators::AllOf.new(1, "2", nil, Integer)
      assert_equal "AllOf(1, \"2\", nil, Integer)", all_of.inspect
    end
  end
end
