# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Attributes::Dsl do
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
        coerce coerce: true
        coerce_method coerce: :some_method
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
      end

      expect(configuration.named!(:no_arguments).validator).to eq(Strict::Validators::Anything.instance)
      expect(configuration.named!(:_underscore_identifier)).not_to be_nil
      expect(configuration.named!(:question?)).not_to be_nil
      expect(configuration.named!(:unsafe!)).not_to be_nil
      expect(configuration.named!(:default_with_value).default_generator.call).to eq(1)
      expect(configuration.named!(:default_with_callable).default_generator.call).to eq(1)
      expect(configuration.named!(:default_value).default_generator.call).to eq(1)
      expect(configuration.named!(:default_generator).default_generator.call).to eq(1)
      coerced = configuration.named!(:coerce).coerce(
        "value",
        for_class: Module.new { def self.coerce_coerce(value) = "coerced #{value}" }
      )
      method_coerced = configuration.named!(:coerce_method).coerce(
        "value",
        for_class: Module.new { def self.some_method(value) = "coerced #{value}" }
      )

      expect(coerced).to eq("coerced value")
      expect(method_coerced).to eq("coerced value")
      expect(configuration.named!(:coerce_array).coerce({ one: 1 }, for_class: nil)).to eq([[:one, 1]])
      expect(configuration.named!(:coerce_array_with).coerce([1, 2], for_class: nil)).to eq(%w[1 2])
      expect(configuration.named!(:coerce_hash).coerce([[:one, 1]], for_class: nil)).to eq(one: 1)
      expect(configuration.named!(:coerce_hash_with).coerce([[:one, 1]], for_class: nil)).to eq("one" => "1")
      expect(configuration.named!(:all_of).validator).to be_an_instance_of(Strict::Validators::AllOf)
      expect(configuration.named!(:any_of).validator).to be_an_instance_of(Strict::Validators::AnyOf)
      expect(configuration.named!(:anything).validator).to be_an_instance_of(Strict::Validators::Anything)
      expect(configuration.named!(:array_of).validator).to be_an_instance_of(Strict::Validators::ArrayOf)
      expect(configuration.named!(:boolean).validator).to be_an_instance_of(Strict::Validators::Boolean)
      expect(configuration.named!(:hash_of).validator).to be_an_instance_of(Strict::Validators::HashOf)
      expect(configuration.named!(:range_of).validator).to be_an_instance_of(Strict::Validators::RangeOf)
    end

    it "rejects duplicate attributes" do
      expect do
        described_class.run do
          foo String
          foo Integer
        end
      end.to raise_error(ArgumentError)
    end

    it "redefines attributes inherited by the declaration in place" do
      inherited = Strict::Attribute.make(:foo, String)

      configuration = described_class.run(attributes: [inherited]) do
        foo Integer
        bar String
      end

      expect(configuration.map(&:name)).to eq(%i[foo bar])
      expect(configuration.named!(:foo).validator).to eq(Integer)
    end

    it "rejects repeated redefinitions in one declaration" do
      inherited = Strict::Attribute.make(:foo, String)

      expect do
        described_class.run(attributes: [inherited]) do
          foo Integer
          foo Numeric
        end
      end.to raise_error(ArgumentError)
    end

    it "allows manually creating attributes" do
      configuration = described_class.run do
        strict_attribute :if
      end

      expect(configuration.map(&:name)).to eq([:if])
    end
  end
end
