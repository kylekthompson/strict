# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Methods::Dsl do
  describe ".run" do
    it "creates a configuration with valid identifiers and arguments" do
      configuration = described_class.run do
        no_arguments
        _underscore_identifier
        question?
        unsafe!
        default_with_value default: 1
        default_with_callable default: -> { 1 }
        default_value default_value: 1
        default_generator default_generator: -> { 1 }
        coerce coerce: ->(value) { "coerced #{value}" }
        coerce_array coerce: ToArray()
        coerce_array_with coerce: ToArray(with: ->(element) { element.to_s })
        coerce_hash coerce: ToHash()
        coerce_hash_with coerce: ToHash(
          with_keys: ->(element) { element.to_s },
          with_values: ->(element) { element.to_s }
        )
        all_of AllOf(Enumerable, Comparable)
        any_of AnyOf(Integer, String, nil)
        anything Anything()
        array_of ArrayOf(Anything())
        boolean Boolean()
        hash_of HashOf(Integer => String)
        range_of RangeOf(Numeric)
        returns Boolean()
      end
      parameters = configuration.parameters.to_h { |p| [p.name, p] }

      expect(parameters.fetch(:no_arguments).validator).to eq(Strict::Validators::Anything.instance)
      expect(parameters.fetch(:_underscore_identifier)).not_to be_nil
      expect(parameters.fetch(:question?)).not_to be_nil
      expect(parameters.fetch(:unsafe!)).not_to be_nil
      expect(parameters.fetch(:default_with_value).default_generator.call).to eq(1)
      expect(parameters.fetch(:default_with_callable).default_generator.call).to eq(1)
      expect(parameters.fetch(:default_value).default_generator.call).to eq(1)
      expect(parameters.fetch(:default_generator).default_generator.call).to eq(1)
      expect(parameters.fetch(:coerce).coerce("value")).to eq("coerced value")
      expect(parameters.fetch(:coerce_array).coerce({ one: 1 })).to eq([[:one, 1]])
      expect(parameters.fetch(:coerce_array_with).coerce([1, 2])).to eq(%w[1 2])
      expect(parameters.fetch(:coerce_hash).coerce([[:one, 1]])).to eq({ one: 1 })
      expect(parameters.fetch(:coerce_hash_with).coerce([[:one, 1]])).to eq({ "one" => "1" })
      expect(parameters.fetch(:all_of).validator).to be_an_instance_of(Strict::Validators::AllOf)
      expect(parameters.fetch(:any_of).validator).to be_an_instance_of(Strict::Validators::AnyOf)
      expect(parameters.fetch(:anything).validator).to be_an_instance_of(Strict::Validators::Anything)
      expect(parameters.fetch(:array_of).validator).to be_an_instance_of(Strict::Validators::ArrayOf)
      expect(parameters.fetch(:boolean).validator).to be_an_instance_of(Strict::Validators::Boolean)
      expect(parameters.fetch(:hash_of).validator).to be_an_instance_of(Strict::Validators::HashOf)
      expect(parameters.fetch(:range_of).validator).to be_an_instance_of(Strict::Validators::RangeOf)
      expect(configuration.returns.validator).to be_an_instance_of(Strict::Validators::Boolean)
    end

    it "allows overwriting parameters" do
      configuration = described_class.run do
        foo String
        foo Integer
      end

      expect(configuration.parameters.map(&:name)).to eq(%i[foo])
      expect(configuration.parameters.map(&:validator)).to eq([Integer])
    end

    it "allows manually creating parameters" do
      configuration = described_class.run do
        strict_parameter :if
      end

      expect(configuration.parameters.map(&:name)).to eq([:if])
    end

    it "allows conflicting returns parameters and declarations" do
      configuration = described_class.run do
        strict_parameter :returns, Integer
        returns Boolean()
      end
      parameters = configuration.parameters.to_h { |p| [p.name, p] }

      expect(parameters.fetch(:returns).validator).to eq(Integer)
      expect(configuration.returns.validator).to be_an_instance_of(Strict::Validators::Boolean)
    end

    it "defines returns as anything when not specified" do
      configuration = described_class.run do
        foo String
      end

      expect(configuration.returns.validator).to be_an_instance_of(Strict::Validators::Anything)
    end
  end
end
