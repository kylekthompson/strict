# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::MethodDefinitionError do
  describe ".new" do
    let(:verifiable_method) do
      Strict::Methods::VerifiableMethod.new(
        method: Strict::Methods::VerifiableMethod.instance_method(:instance?),
        parameters: [],
        returns: [],
        instance: true
      )
    end

    it "builds a message with only missing parameters" do
      error = described_class.new(
        verifiable_method: verifiable_method,
        missing_parameters: %i[one two],
        additional_parameters: []
      )

      expected_message = <<~MESSAGE.chomp
        Defining Strict::Methods::VerifiableMethod#instance? failed because:
          Some parameters were in the sig, but were not in the parameter list:
            - one
            - two
      MESSAGE

      expect(error.message).to eq(expected_message)
    end

    it "builds a message with only additional parameters" do
      error = described_class.new(
        verifiable_method: verifiable_method,
        missing_parameters: [],
        additional_parameters: %i[one two]
      )

      expected_message = <<~MESSAGE.chomp
        Defining Strict::Methods::VerifiableMethod#instance? failed because:
          Some parameters were not in the sig, but were in the parameter list:
            - one
            - two
      MESSAGE

      expect(error.message).to eq(expected_message)
    end

    it "builds a message with all kinds of problems" do
      error = described_class.new(
        verifiable_method: verifiable_method,
        missing_parameters: %i[one two],
        additional_parameters: %i[three four]
      )

      expected_message = <<~MESSAGE.chomp
        Defining Strict::Methods::VerifiableMethod#instance? failed because:
          Some parameters were in the sig, but were not in the parameter list:
            - one
            - two
          Some parameters were not in the sig, but were in the parameter list:
            - three
            - four
      MESSAGE

      expect(error.message).to eq(expected_message)
    end
  end
end
