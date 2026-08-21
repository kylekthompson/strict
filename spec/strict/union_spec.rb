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

  it "generates an interrogation method for each variant" do
    authorized = union_class::Authorized.new(authorization_id: "auth_123", amount_in_cents: 1_000)
    declined = union_class::Declined.new(reason: "insufficient_funds")

    expect(authorized.authorized?).to be(true)
    expect(authorized.declined?).to be(false)
    expect(declined.authorized?).to be(false)
    expect(declined.declined?).to be(true)
  end

  it "generates a class-level constructor for each variant" do
    authorized = union_class.authorized(authorization_id: "auth_123", amount_in_cents: 1_000)
    declined = union_class.declined(reason: "insufficient_funds")

    expect(authorized).to eq(
      union_class::Authorized.new(authorization_id: "auth_123", amount_in_cents: 1_000)
    )
    expect(declined).to eq(union_class::Declined.new(reason: "insufficient_funds"))
  end

  it "shares union attributes across variants" do
    result_class = Class.new do
      include Strict::Union

      discriminator :status

      attributes do
        request_id String
      end

      variant :authorized do
        attributes do
          authorization_id String
        end
      end

      variant :declined
    end

    authorized = result_class::Authorized.new(request_id: "request_123", authorization_id: "auth_123")
    declined = result_class.coercer.call(status: :declined, request_id: "request_456")

    expect(authorized.to_h).to eq(status: :authorized, request_id: "request_123", authorization_id: "auth_123")
    expect(declined.to_h).to eq(status: :declined, request_id: "request_456")
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
    convenience = result_class.authorized(authorization_id: "auth_123")

    expect(authorized.to_h).to eq(status: "some-string", authorization_id: "auth_123")
    expect(string_input).to eq(authorized)
    expect(symbol_input).to eq(authorized)
    expect(convenience).to eq(authorized)
    expect(convenience.authorized?).to be(true)
  end

  it "automatically coerces values when used as an attribute validator" do
    result_class = union_class
    container_class = Class.new do
      include Strict::Value

      attributes do
        payment_result result_class
      end
    end
    payment_result = union_class::Declined.new(reason: "insufficient_funds")

    container = container_class.new(
      payment_result: { "status" => "declined", "reason" => "insufficient_funds" }
    )

    expect(container.payment_result).to eq(payment_result)
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

  it "requires one union attribute declaration before variants" do
    result_class = Class.new do
      include Strict::Union

      discriminator :kind
      attributes { request_id String }
    end

    expect do
      result_class.attributes { account_id String }
    end.to raise_error(ArgumentError, /attributes already declared/)

    result_class_without_attributes = Class.new do
      include Strict::Union

      discriminator :kind
      variant :complete
    end

    expect do
      result_class_without_attributes.attributes { request_id String }
    end.to raise_error(ArgumentError, /attributes must be declared before variants/)
  end

  it "rejects discriminator attributes in union declarations" do
    expect do
      Class.new do
        include Strict::Union

        discriminator :kind
        attributes { kind Symbol }
      end
    end.to raise_error(ArgumentError, /cannot redeclare discriminator :kind/)

    expect do
      Class.new do
        include Strict::Union

        attributes { kind Symbol }
        discriminator :kind
      end
    end.to raise_error(ArgumentError, /cannot redeclare discriminator :kind/)
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
    end.to raise_error(ArgumentError)
  end

  it "rejects variant attributes that duplicate shared attributes" do
    expect do
      Class.new do
        include Strict::Union

        discriminator :kind
        attributes { request_id String }
        variant :invalid do
          attributes { request_id Integer }
        end
      end
    end.to raise_error(ArgumentError)
  end

  it "rejects attributes that share backing storage across a composed variant" do
    expect do
      Class.new do
        include Strict::Union

        discriminator :kind
        attributes { request_id String }
        variant :invalid do
          attributes { request_id? Boolean() }
        end
      end
    end.to raise_error(ArgumentError, /Attribute :request_id\? conflicts with :request_id/)

    expect do
      Class.new do
        include Strict::Union

        attributes { kind? Boolean() }
        discriminator :kind
      end
    end.to raise_error(ArgumentError, /union attributes cannot conflict with discriminator :kind/)
  end

  it "rejects variant attributes that collide with variant methods" do
    expect do
      Class.new do
        include Strict::Union

        discriminator :kind
        variant :invalid do
          def result = "method"

          attributes { result String }
        end
      end
    end.to raise_error(ArgumentError)
  end

  it "rejects variant behavior that collides with its interrogation method" do
    expect do
      Class.new do
        include Strict::Union

        discriminator :kind
        variant :complete do
          def complete? = false
        end
      end
    end.to raise_error(ArgumentError, /interrogation method :complete\? already exists/)
  end

  it "rejects behavior that collides with another variant's interrogation method" do
    future_collision = Class.new do
      include Strict::Union

      discriminator :kind
      variant :first do
        def second? = false
      end
    end
    existing_collision = Class.new do
      include Strict::Union

      discriminator :kind
      variant :first
    end

    expect do
      future_collision.variant :second
    end.to raise_error(ArgumentError, /interrogation method :second\? already exists/)
    expect do
      existing_collision.variant :second do
        def first? = false
      end
    end.to raise_error(ArgumentError, /interrogation method :first\? already exists/)
  end

  it "rejects variant names that collide with class-level convenience methods" do
    expect do
      Class.new do
        include Strict::Union

        discriminator :kind
        variant :name
      end
    end.to raise_error(ArgumentError, /variant convenience method :name already exists/)
  end
end
