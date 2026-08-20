# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Union do
  let(:union_class) do
    Class.new do
      include Strict::Union

      discriminator :status

      variant :authorized do
        attributes do
          authorization_id String
          amount_in_cents Integer
        end
      end

      variant :declined do
        attributes do
          reason String
        end
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

  it "defines behavior on generated variant classes" do
    behavior = Module.new do
      def successful? = true
    end
    result_class = Class.new do
      include Strict::Union

      discriminator :status

      variant :authorized do
        include behavior

        attributes do
          authorization_id String
        end

        def description = "Authorized as #{authorization_id}"
      end
    end
    authorized = result_class::Authorized.new(authorization_id: "auth_123")

    expect(authorized.successful?).to be(true)
    expect(authorized.description).to eq("Authorized as auth_123")
  end

  it "dispatches symbol- and string-keyed hashes by symbol or string tags" do
    symbol_input = union_class.coercer.call(status: :authorized, authorization_id: "auth_123", amount_in_cents: 1_000)
    string_input = union_class.coercer.call("status" => "declined", "reason" => "insufficient_funds")

    expect(symbol_input).to eq(
      union_class::Authorized.new(authorization_id: "auth_123", amount_in_cents: 1_000)
    )
    expect(string_input).to eq(union_class::Declined.new(reason: "insufficient_funds"))
  end

  it "separates variant names from discriminator tags" do
    result_class = Class.new do
      include Strict::Union

      discriminator :status
      variant :authorized, tag: "some-string" do
        attributes do
          authorization_id String
        end
      end
    end

    authorized = result_class::Authorized.new(status: :"some-string", authorization_id: "auth_123")
    string_input = result_class.coercer.call(status: "some-string", authorization_id: "auth_123")
    symbol_input = result_class.coercer.call(status: :"some-string", authorization_id: "auth_123")

    expect(authorized.to_h).to eq(status: "some-string", authorization_id: "auth_123")
    expect(string_input).to eq(authorized)
    expect(symbol_input).to eq(authorized)
  end

  it "works as an attribute validator with optional coercion" do
    result_class = union_class
    container_class = Class.new do
      include Strict::Value

      attributes do
        payment_result result_class
        coerced_payment_result result_class, coerce: result_class.coercer
      end
    end
    payment_result = union_class::Declined.new(reason: "insufficient_funds")

    container = container_class.new(
      payment_result: payment_result,
      coerced_payment_result: { "status" => "declined", "reason" => "insufficient_funds" }
    )

    expect(container.payment_result).to be(payment_result)
    expect(container.coerced_payment_result).to eq(payment_result)
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
      status: "authorized",
      authorization_id: "auth_123",
      amount_in_cents: 1_000
    )

    expect(authorized.status).to eq(:authorized)
    expect do
      Strict.with_overrides(sample_rate: 0) do
        union_class::Authorized.new(
          status: :declined,
          authorization_id: "auth_123",
          amount_in_cents: 1_000
        )
      end
    end.to raise_error(ArgumentError, /discriminator :status must equal :authorized/)
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

  it "generates PascalCase constants from lower snake_case names and permits empty variants" do
    generated_union = Class.new do
      include Strict::Union

      discriminator :kind
      variant :requires_action
    end

    expect(generated_union::RequiresAction.new.to_h).to eq(kind: :requires_action)
  end

  it "rejects multiple attribute declarations for one variant" do
    expect do
      Class.new do
        include Strict::Union

        discriminator :kind
        variant :invalid do
          attributes { first String }
          attributes { second String }
        end
      end
    end.to raise_error(ArgumentError, /attributes already declared for variant :invalid/)
  end

  it "rejects equivalent duplicate discriminator tags" do
    duplicate_tag = Class.new do
      include Strict::Union

      discriminator :kind
      variant :first, tag: "same"
    end

    expect do
      duplicate_tag.variant(:second, tag: :same)
    end.to raise_error(ArgumentError, /tag :same already declared/)
  end

  it "requires discriminator tags to be strings or symbols" do
    invalid_tag = Class.new do
      include Strict::Union

      discriminator :kind
    end

    expect do
      invalid_tag.variant(:invalid, tag: 1)
    end.to raise_error(ArgumentError, /tag must be a String or Symbol/)
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
          attributes do
            kind Symbol
          end
        end
      end
    end.to raise_error(ArgumentError, /cannot redeclare discriminator :kind/)
  end
end
