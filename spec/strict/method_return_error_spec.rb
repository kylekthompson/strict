# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::MethodReturnError do
  describe ".new" do
    let(:verifiable_method) do
      method = Strict::Methods::VerifiableMethod.instance_method(:instance?)
      configuration = Strict::Methods::Configuration.new(
        parameters: [],
        returns: Strict::Return.make(Strict::Validators::AnyOf.new(1, "2", nil))
      )
      Strict::Methods::VerifiableMethod.from_method(
        method: method,
        configuration: configuration,
        instance: true
      )
    end

    it "builds a message with an invalid value" do
      error = described_class.new(verifiable_method: verifiable_method, value: 2)

      expected_message = <<~MESSAGE.chomp
        Strict::Methods::VerifiableMethod#instance?'s return value was invalid because:
          - got 2, expected AnyOf(1, "2", nil)
      MESSAGE

      expect(error.message).to eq(expected_message)
    end
  end
end
