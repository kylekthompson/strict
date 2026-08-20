# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Violation do
  it "describes an invalid assignment" do
    object_class = Class.new do
      include Strict::Object

      attributes { count Integer }
    end
    object = object_class.new(count: 1)

    expect do
      object.count = "one"
    end.to raise_error(Strict::AssignmentError) { |error|
      violation = error.violations.fetch(0)

      expect(violation).to be_a(described_class)
      expect(violation.path).to eq([:count])
      expect(violation.code).to eq(:invalid)
      expect(violation.value).to eq("one")
      expect(violation.validator).to equal(Integer)
    }
  end

  it "describes structural and nested initialization failures" do
    value_class = Class.new do
      include Strict::Value

      attributes do
        name String
        scores ArrayOf(Integer)
        groups HashOf(Symbol => ArrayOf(String))
      end
    end

    expect do
      value_class.new(
        scores: [1, "two"],
        groups: { "admins" => ["one"], members: ["two", 3] },
        extra: true
      )
    end.to raise_error(Strict::InitializationError) { |error|
      expect(error.violations.map { |violation|
        [violation.path, violation.code, violation.value, violation.validator]
      }).to contain_exactly(
        [[:name], :missing, nil, String],
        [[:scores, 1], :invalid, "two", Integer],
        [[:groups, "admins"], :invalid, "admins", Symbol],
        [[:groups, :members, 1], :invalid, 3, String],
        [[:extra], :unexpected, true, nil]
      )
    }
  end

  it "describes invalid, missing, and unexpected method arguments" do
    method_class = Class.new do
      include Strict::Method

      sig do
        items ArrayOf(Integer)
        required String
      end
      def call(items, required:); end
    end

    expect do
      method_class.new.call([1, "two"], :extra, unexpected: true)
    end.to raise_error(Strict::MethodCallError) { |error|
      expect(error.violations.map { |violation|
        [violation.path, violation.code, violation.value, violation.validator]
      }).to contain_exactly(
        [[:items, 1], :invalid, "two", Integer],
        [[:required], :missing, nil, String],
        [[1], :unexpected, :extra, nil],
        [[:unexpected], :unexpected, true, nil]
      )
    }
  end

  it "describes an invalid method return from its root path" do
    method_class = Class.new do
      include Strict::Method

      sig { returns ArrayOf(String) }
      def call = ["one", 2]
    end

    expect do
      method_class.new.call
    end.to raise_error(Strict::MethodReturnError) { |error|
      violation = error.violations.fetch(0)

      expect(violation.path).to eq([1])
      expect(violation.code).to eq(:invalid)
      expect(violation.value).to eq(2)
      expect(violation.validator).to equal(String)
    }
  end

  it "preserves nested paths through composed validators" do
    value_class = Class.new do
      include Strict::Value

      attributes { items AllOf(Array, ArrayOf(Integer)) }
    end

    expect do
      value_class.new(items: [1, "two"])
    end.to raise_error(Strict::InitializationError) { |error|
      violation = error.violations.fetch(0)

      expect(violation.path).to eq([:items, 1])
      expect(violation.value).to eq("two")
      expect(violation.validator).to equal(Integer)
    }
  end

  it "supports validators that only implement case equality" do
    validated_values = []
    validator = Object.new
    validator.define_singleton_method(:===) do |value|
      validated_values << value
      false
    end
    value_class = Class.new do
      include Strict::Value

      attributes { value validator }
    end

    expect do
      value_class.new(value: :invalid)
    end.to raise_error(Strict::InitializationError) { |error|
      expect(error.violations.fetch(0).validator).to equal(validator)
    }
    expect(validated_values).to eq([:invalid])
  end
end
