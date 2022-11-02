# frozen_string_literal: true

require "test_helper"

describe Strict::Validators::AnyOf do
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
      any_of = Strict::Validators::AnyOf.new(@validates, @validates, @validates)

      assert any_of === @value
    end

    it "validates when some subvalidators validate" do
      any_of = Strict::Validators::AnyOf.new(@validates, @invalidates, @validates)

      assert any_of === @value
    end

    it "does not validate when no subvalidators validate" do
      any_of = Strict::Validators::AnyOf.new(@invalidates, @invalidates, @invalidates)

      refute any_of === @value
    end
  end

  describe "#to_s" do
    it "is meaningful" do
      any_of = Strict::Validators::AnyOf.new(1, "2", nil, Integer)

      assert_equal "AnyOf(1, \"2\", nil, Integer)", any_of.to_s
    end
  end

  describe "#inspect" do
    it "is meaningful" do
      any_of = Strict::Validators::AnyOf.new(1, "2", nil, Integer)

      assert_equal "AnyOf(1, \"2\", nil, Integer)", any_of.inspect
    end
  end
end
