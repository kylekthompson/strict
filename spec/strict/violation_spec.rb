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
end
