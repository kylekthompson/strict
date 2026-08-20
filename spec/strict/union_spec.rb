# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Union do
  let(:union_class) do
    Class.new do
      include Strict::Union

      discriminator :status

      variant :authorized do
        authorization_id String
        amount_in_cents Integer
      end

      variant :declined do
        reason String
      end
    end
  end

  it "generates tagged Strict::Value subclasses" do
    authorized = union_class::Authorized.new(authorization_id: "auth_123", amount_in_cents: 1_000)
    equal_authorized = union_class::Authorized.new(authorization_id: "auth_123", amount_in_cents: 1_000)
    declined = union_class::Declined.new(reason: "insufficient_funds")

    expect(union_class::Authorized.superclass).to be(union_class)
    expect(union_class::Authorized < Strict::Value).to be(true)
    expect(authorized.to_h).to eq(status: :authorized, authorization_id: "auth_123", amount_in_cents: 1_000)
    expect(declined.to_h).to eq(status: :declined, reason: "insufficient_funds")
    expect(authorized).to eq(equal_authorized)
    expect(authorized.hash).to eq(equal_authorized.hash)
    expect(authorized.with(amount_in_cents: 2_000).amount_in_cents).to eq(2_000)
    expect(union_class === authorized).to be(true)
    expect(union_class === declined).to be(true)
  end

  it "dispatches symbol- and string-keyed hashes by symbol or string tags" do
    symbol_input = union_class.coercer.call(status: :authorized, authorization_id: "auth_123", amount_in_cents: 1_000)
    string_input = union_class.coercer.call("status" => "declined", "reason" => "insufficient_funds")

    expect(symbol_input).to eq(
      union_class::Authorized.new(authorization_id: "auth_123", amount_in_cents: 1_000)
    )
    expect(string_input).to eq(union_class::Declined.new(reason: "insufficient_funds"))
  end

  it "leaves existing members, nil, and non-hash-like values unchanged" do
    member = union_class::Declined.new(reason: "insufficient_funds")

    expect(union_class.coercer.call(member)).to be(member)
    expect(union_class.coercer.call(nil)).to be_nil
    expect(union_class.coercer.call("declined")).to eq("declined")
  end

  it "rejects missing and unknown discriminators precisely" do
    expect do
      union_class.coercer.call(reason: "insufficient_funds")
    end.to raise_error(ArgumentError, /missing discriminator :status/)

    expect do
      union_class.coercer.call(status: :pending)
    end.to raise_error(ArgumentError, /unknown discriminator :status.*:pending/)
  end

  it "requires one explicit discriminator before variants or coercion" do
    incomplete_union = Class.new { include Strict::Union }

    expect { incomplete_union.variant(:pending) }.to raise_error(ArgumentError, /declare a discriminator/)
    expect { incomplete_union.coercer }.to raise_error(ArgumentError, /declare a discriminator/)
  end

  it "prohibits direct base construction and keeps membership closed" do
    member_subclass = Class.new(union_class::Declined)
    member_subclass_instance = member_subclass.new(reason: "insufficient_funds")

    expect { union_class.new }.to raise_error(TypeError, /cannot instantiate union/)
    expect(union_class === member_subclass_instance).to be(false)
    expect(union_class::Declined === member_subclass_instance).to be(true)
  end

  it "keeps each variant discriminator fixed" do
    authorized = union_class::Authorized.new(
      status: :authorized,
      authorization_id: "auth_123",
      amount_in_cents: 1_000
    )

    expect(authorized.status).to eq(:authorized)
    expect do
      union_class::Authorized.new(
        status: :declined,
        authorization_id: "auth_123",
        amount_in_cents: 1_000
      )
    end.to raise_error(Strict::InitializationError)
  end

  it "supports standard Ruby class and attribute patterns" do
    stub_const("PatternResult", union_class)
    authorized = PatternResult::Authorized.new(authorization_id: "auth_123", amount_in_cents: 1_000)

    result = case authorized
             in PatternResult::Authorized(authorization_id:, amount_in_cents:)
               [authorization_id, amount_in_cents]
             else
               nil
             end

    expect(result).to eq(["auth_123", 1_000])
  end

  it "generates PascalCase constants from lower snake_case tags and permits empty variants" do
    generated_union = Class.new do
      include Strict::Union

      discriminator :kind
      variant :requires_action
    end

    expect(generated_union::RequiresAction.new.to_h).to eq(kind: :requires_action)
  end

  it "rejects duplicate declarations and generated constant collisions" do
    duplicate_discriminator = Class.new do
      include Strict::Union

      discriminator :kind
    end
    duplicate_variant = Class.new do
      include Strict::Union

      discriminator :kind
      variant :some_result
    end
    constant_collision = Class.new do
      include Strict::Union

      discriminator :kind
      const_set(:Existing, Class.new)
    end

    expect do
      duplicate_discriminator.discriminator(:type)
    end.to raise_error(ArgumentError, /discriminator already declared/)
    expect do
      duplicate_variant.variant("some_result")
    end.to raise_error(ArgumentError, /variant :some_result already declared/)
    expect do
      constant_collision.variant(:existing)
    end.to raise_error(ArgumentError, /constant Existing is already defined/)
    expect do
      duplicate_variant.variant(:not_valid!)
    end.to raise_error(ArgumentError, /variant name must be lower snake_case/)
  end

  it "rejects discriminator attributes in variant declarations" do
    expect do
      Class.new do
        include Strict::Union

        discriminator :kind
        variant :invalid do
          kind Symbol
        end
      end
    end.to raise_error(ArgumentError, /cannot redeclare discriminator :kind/)
  end
end
