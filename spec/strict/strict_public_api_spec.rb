# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict do
  describe "capability inclusion" do
    it "adds each capability with include" do
      value_class = Class.new { include Strict::Value }
      object_class = Class.new { include Strict::Object }
      method_class = Class.new { include Strict::Method }
      interface_class = Class.new { include Strict::Interface }
      union_class = Class.new { include Strict::Union }

      expect(value_class).to respond_to(:attributes)
      expect(object_class).to respond_to(:attributes)
      expect(method_class).to respond_to(:sig)
      expect(interface_class).to respond_to(:expose)
      expect(union_class).to respond_to(:attributes, :discriminator, :variant, :coercer)
    end
  end

  describe "values" do
    it "supports declarations, coercion, defaults, introspection, copying, equality, and hashing" do
      generated_default = 0
      callable_value = -> { "callable value" }
      value_class = Class.new do
        include Strict::Value

        def self.coerce_count(value) = value.to_i
        def self.stringify(value) = value.to_s

        attributes do
          strict_attribute :if, String
          active? Boolean()
          count Integer, coerce: true
          symbol_coerced String, coerce: :stringify
          callable_coerced Integer, coerce: ->(value) { value.to_i }
          static_default String, default: "static"
          generated_default Integer, default: -> { # rubocop:disable Style/Lambda
            generated_default += 1
            1
          }
          callable_value Anything(), default_value: callable_value
          explicit_generator String, default_generator: -> { "generated" }
        end
      end
      attributes = {
        if: "yes",
        active?: true,
        count: "1",
        symbol_coerced: 2,
        callable_coerced: "3"
      }
      value = value_class.new(**attributes)
      equal_value = value_class.new(**attributes)

      expected_attributes = {
        **attributes,
        count: 1,
        symbol_coerced: "2",
        callable_coerced: 3,
        static_default: "static",
        generated_default: 1,
        callable_value: callable_value,
        explicit_generator: "generated"
      }
      expect(value.to_h).to eq(expected_attributes)
      expect(value.as_json).to eq(expected_attributes)
      expect(value.public_send(:if)).to eq("yes")
      expect(value.active?).to be(true)
      expect(value).to eq(equal_value)
      expect(value).to eql(equal_value)
      expect(value.hash).to eq(equal_value.hash)
      expect(value.with(count: 4).count).to eq(4)

      descriptors = value_class.strict_attributes.to_a
      expect(descriptors.map(&:name)).to eq(
        %i[if active? count symbol_coerced callable_coerced static_default generated_default callable_value
           explicit_generator]
      )
      expect(descriptors.first.validator === "a string").to be(true)
      expect(descriptors.first.optional?).to be(false)
      expect(descriptors.last.optional?).to be(true)

      expect(value_class.coercer.call(nil)).to be_nil
      expect(value_class.coercer.call("unchanged")).to eq("unchanged")
      coerced = value_class.coercer.call(attributes.transform_keys(&:to_s))
      expect(coerced).to eq(value)

      child_class = Class.new(value_class)
      child_value = child_class.new(**attributes)
      equal_child_value = child_class.new(**attributes)
      expect(child_value).to eq(equal_child_value)
    end

    it "derives hashes, equality, and hash codes from declared readers" do
      value_class = Class.new do
        include Strict::Value

        attributes { amount Integer }
      end
      value_with_overridden_reader = value_class.new(amount: 1)
      equal_value = value_class.new(amount: 2)
      value_with_overridden_reader.define_singleton_method(:amount) { 2 }

      expect(value_with_overridden_reader.to_h).to eq(amount: 2)
      expect(value_with_overridden_reader).to eql(equal_value)
      expect(value_with_overridden_reader.hash).to eq(equal_value.hash)
    end

    it "makes conventional backing instance variables available to custom behavior" do
      value_class = Class.new do
        include Strict::Value

        attributes do
          name String
          active? Boolean()
        end

        def state = [@name, @active]
      end
      value = value_class.new(name: "Ada", active?: true)

      expect(value.state).to eq(["Ada", true])
      expect(value.instance_variables).to contain_exactly(:@name, :@active)
    end

    it "rejects attribute names that use the same backing instance variable" do
      expect do
        Class.new do
          include Strict::Value

          attributes do
            strict_attribute :value, String
            strict_attribute :value?, Integer
          end
        end
      end.to raise_error(ArgumentError, /Attribute :value\? conflicts with :value/)
    end

    it "rejects invalid attribute declarations before installing methods" do
      invalid_declarations = [
        -> { attributes { strict_attribute :"name=", String } },
        -> { attributes { name String, default_generator: "not callable" } },
        -> { attributes { name String, coerce: Object.new } },
        lambda do
          attributes do
            name String
            name Integer
          end
        end,
        -> { attributes { as_json Hash } },
        -> { attributes { to_h Hash } }
      ]

      invalid_declarations.each do |declaration|
        expect do
          Class.new do
            include Strict::Value

            class_exec(&declaration)
          end
        end.to raise_error(ArgumentError)
      end
    end

    it "rejects repeated and inherited attribute declarations" do
      parent_class = Class.new do
        include Strict::Value

        attributes { name String }
      end

      expect do
        Class.new(parent_class) { attributes { name String } }
      end.to raise_error(ArgumentError)

      expect do
        Class.new(parent_class) { attributes { name? Boolean() } }
      end.to raise_error(ArgumentError, /Attribute :name\? conflicts with :name/)

      expect do
        parent_class.attributes { employee_id String }
      end.to raise_error(ArgumentError)
    end
  end

  describe "objects" do
    it "supports validated reserved and punctuation writers and retains identity equality" do
      object_class = Class.new do
        include Strict::Object

        attributes do
          strict_attribute :if, String
          active? Boolean()
          dangerous! Boolean()
        end
      end
      object = object_class.new(if: "yes", active?: true, dangerous!: false)
      other = object_class.new(if: "yes", active?: true, dangerous!: false)

      object.public_send(:"if=", "still yes")
      object.public_send(:"active?=", false)
      object.public_send(:"dangerous!=", true)

      expect(object.to_h).to eq(if: "still yes", active?: false, dangerous!: true)
      expect(object).not_to eq(other)
      expect(object).not_to respond_to(:with)
      expect do
        object.public_send(:"active?=", "no")
      end.to raise_error(Strict::AssignmentError) { |error| expect(error.value).to eq("no") }
    end

    it "updates conventional backing instance variables through validated writers" do
      object_class = Class.new do
        include Strict::Object

        attributes do
          name String
          active? Boolean()
        end

        def state = [@name, @active]
      end
      object = object_class.new(name: "Ada", active?: true)

      object.name = "Grace"
      object.public_send(:"active?=", false)

      expect(object.state).to eq(["Grace", false])
      expect(object.instance_variables).to contain_exactly(:@name, :@active)
    end

    it "inherits writers and resolves class coercers on the receiving class" do
      parent_class = Class.new do
        include Strict::Object

        def self.symbolic(value) = "parent #{value}"

        attributes do
          automatic String, coerce: true
          symbolic String, coerce: :symbolic
        end
      end
      child_class = Class.new(parent_class) do
        def self.coerce_automatic(value) = "child #{value}"
        def self.symbolic(value) = "child #{value}"
      end
      object = child_class.new(automatic: "initial", symbolic: "initial")

      object.automatic = "assigned"
      object.symbolic = "assigned"

      expect(object.to_h).to eq(automatic: "child assigned", symbolic: "child assigned")
    end

    it "rejects an attribute whose generated writer already exists" do
      expect do
        Class.new do
          include Strict::Object

          def name=(_value); end

          attributes { name String }
        end
      end.to raise_error(ArgumentError)
    end

    it "coerces before sampling each assignment once" do
      validations = []
      coercions = []
      validator = Object.new
      validator.define_singleton_method(:===) do |value|
        validations << value
        value == "initial"
      end
      coercer = lambda do |value|
        coercions << value
        value.to_s
      end
      object_class = Class.new do
        include Strict::Object

        attributes do
          value validator, coerce: coercer
        end
      end
      object = object_class.new(value: "initial")
      validations.clear
      coercions.clear
      random_values = [0.75, 0.25]
      random = Object.new.extend(Random::Formatter)
      random.define_singleton_method(:rand) { random_values.shift }
      error = nil

      described_class.with_overrides(random: random, sample_rate: 0.5) do
        object.value = 1
        expect do
          object.value = 2
        end.to raise_error(Strict::AssignmentError) { |raised_error| error = raised_error }
      end

      expect(object.value).to eq("1")
      expect(error.value).to eq("2")
      expect(coercions).to eq([1, 2])
      expect(validations).to eq(["2"])
      expect(random_values).to be_empty
    end
  end

  describe "validators and coercers" do
    it "provides the supported constructors inside attribute declarations" do
      custom_validator = Object.new
      custom_validator.define_singleton_method(:===) { |value| value == :custom }
      value_class = Class.new do
        include Strict::Value

        attributes do
          all AllOf(Integer, 1..10)
          any AnyOf(String, nil)
          anything Anything()
          array ArrayOf(Integer)
          boolean Boolean()
          hash_value HashOf(Symbol => Integer)
          range RangeOf(Integer)
          custom custom_validator
          coerced_array ArrayOf(String), coerce: ToArray(with: ->(value) { value.to_s })
          coerced_hash HashOf(String => String), coerce: ToHash(
            with_keys: ->(value) { value.to_s },
            with_values: ->(value) { value.to_s }
          )
        end
      end
      value = value_class.new(
        all: 5,
        any: nil,
        anything: Object.new,
        array: [1, 2],
        boolean: false,
        hash_value: { one: 1 },
        range: 1..3,
        custom: :custom,
        coerced_array: [1, 2],
        coerced_hash: { one: 1 }
      )

      expect(value.coerced_array).to eq(%w[1 2])
      expect(value.coerced_hash).to eq("one" => "1")
      expect do
        value_class.new(
          all: 11,
          any: nil,
          anything: nil,
          array: [],
          boolean: true,
          hash_value: {},
          range: 1..3,
          custom: :custom,
          coerced_array: [],
          coerced_hash: {}
        )
      end.to raise_error(Strict::InitializationError)
    end

    it "propagates coercion through array and hash validators" do
      item_class = Class.new do
        include Strict::Value

        attributes do
          name String
        end
      end
      collection_class = Class.new do
        include Strict::Value

        attributes do
          items ArrayOf(item_class)
          items_by_group HashOf(String => ArrayOf(item_class))
        end
      end

      collection = collection_class.new(
        items: [{ name: "one" }],
        items_by_group: [["all", [{ name: "one" }]]]
      )

      item = item_class.new(name: "one")
      expect(collection.items).to eq([item])
      expect(collection.items_by_group).to eq("all" => [item])
    end
  end

  describe "signed methods" do
    it "supports parameter forms, coercion, defaults, blocks, and singleton methods" do
      method_class = Class.new do
        include Strict::Method

        sig do
          first Integer, coerce: ->(value) { value.to_i }
          rest Array
          factor Integer, default: 2
          options Hash
          returns Array
        end
        def call(first, *rest, factor:, **options, &block)
          [first, rest, factor, options, block.call]
        end

        sig do
          strict_parameter :if, String
          returns String
        end
        singleton_class.class_eval("def reserved(if:); binding.local_variable_get(:if); end", __FILE__, __LINE__)
      end

      expect(method_class.new.call("1", 2, 3, extra: true) { :block }).to eq(
        [1, [2, 3], 2, { extra: true }, :block]
      )
      expect(method_class.reserved(if: "yes")).to eq("yes")
    end

    it "samples each parameter and the return value independently" do
      validations = []
      validator = lambda do |name|
        Object.new.tap do |value|
          value.define_singleton_method(:===) do |_argument|
            validations << name
            true
          end
        end
      end
      random_values = [0.25, 0.75, 0.25]
      random = Object.new.extend(Random::Formatter)
      random.define_singleton_method(:rand) { random_values.shift }
      method_class = Class.new do
        include Strict::Method

        sig do
          first validator.call(:first)
          second validator.call(:second)
          returns validator.call(:return)
        end
        def call(first, second) = first + second
      end

      result = described_class.with_overrides(random: random, sample_rate: 0.5) { method_class.new.call(1, 2) }

      expect(result).to eq(3)
      expect(validations).to eq(%i[first return])
      expect(random_values).to be_empty
    end

    it "supports an optional positional parameter before a required positional parameter" do
      method_class = Class.new do
        include Strict::Method

        sig do
          prefix String, default: "default"
          value Integer
          returns Array
        end
        # rubocop:disable Style/OptionalArguments
        def call(prefix = nil, value) = [prefix, value]
        # rubocop:enable Style/OptionalArguments
      end
      method = method_class.new

      expect(method.call(1)).to eq(["default", 1])
      expect(method.call("given", 1)).to eq(["given", 1])
    end

    it "keeps inherited signed methods validated and treats unsigned overrides normally" do
      parent_class = Class.new do
        include Strict::Method

        sig do
          value Integer
          returns Integer
        end
        def call(value) = value
      end
      inherited_class = Class.new(parent_class)
      overridden_class = Class.new(parent_class) { def call(value) = value }

      expect(inherited_class.new.call(1)).to eq(1)
      expect { inherited_class.new.call("1") }.to raise_error(Strict::MethodCallError)
      expect(overridden_class.new.call("1")).to eq("1")
    end

    it "keeps inherited signed singleton methods validated and treats unsigned overrides normally" do
      parent_class = Class.new do
        include Strict::Method

        sig do
          value Integer
          returns Integer
        end
        def self.call(value) = value
      end
      inherited_class = Class.new(parent_class)
      overridden_class = Class.new(parent_class) do
        class << self
          def call(value) = value
        end
      end

      expect(inherited_class.call(1)).to eq(1)
      expect { inherited_class.call("1") }.to raise_error(Strict::MethodCallError)
      expect(overridden_class.call("1")).to eq("1")
    end

    it "validates and preserves the exact returned object" do
      returned = Object.new
      method_class = Class.new do
        include Strict::Method

        sig { returns Object }
        define_method(:call) { returned }
      end

      expect(method_class.new.call).to be(returned)
    end

    it "rejects return coercion when declaring the signature" do
      expect do
        Class.new do
          include Strict::Method

          sig { returns String, coerce: ->(value) { value.to_s } }
        end
      end.to raise_error(ArgumentError)
    end

    it "rejects invalid and duplicate signature declarations" do
      invalid_signatures = [
        lambda do
          sig do
            value Integer
            value String
          end
        end,
        lambda do
          sig do
            returns String
            returns Integer
          end
        end,
        -> { sig { value Integer, coerce: true } },
        -> { sig { value Integer, default_generator: 1 } },
        -> { sig { strict_parameter :"value=", String } }
      ]

      invalid_signatures.each do |signature|
        expect do
          Class.new do
            include Strict::Method

            class_exec(&signature)
          end
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe "interfaces" do
    it "checks implementations, forwards reserved keywords, and exposes coercion and implementation" do
      interface_class = Class.new do
        include Strict::Interface

        expose(:if) do
          strict_parameter :if, String
          returns String
        end
      end
      implementation = Class.new do
        class_eval("def if(if:); binding.local_variable_get(:if); end", __FILE__, __LINE__)
      end.new
      interface = interface_class.new(implementation)

      expect(interface.implementation).to be(implementation)
      expect(interface.public_send(:if, if: "yes")).to eq("yes")
      expect(interface_class.coercer.call(nil)).to be_nil
      expect(interface_class.coercer.call(interface)).to be(interface)
      expect(interface_class.coercer.call(implementation).implementation).to be(implementation)

      receiver = Object.new
      expect do
        interface_class.new(receiver)
      end.to raise_error(Strict::ImplementationDoesNotConformError) { |error|
        expect(error.interface).to be(interface_class)
        expect(error.receiver).to be(receiver)
        expect(error.missing_methods).to eq([:if])
        expect(error.invalid_method_definitions).to be_empty
      }
    end

    it "forwards coerced and defaulted keywords and blocks through punctuation method names" do
      interface_class = Class.new do
        include Strict::Interface

        expose(:transform!) do
          value Integer, coerce: ->(value) { value.to_i }
          suffix String, default: "!"
          returns String
        end
      end
      implementation = Class.new do
        define_method(:transform!) do |value:, suffix:, &block|
          "#{block.call(value)}#{suffix}"
        end
      end.new

      result = interface_class.new(implementation).transform!(value: "2") { |value| value * 3 }

      expect(result).to eq("6!")
    end

    it "validates exposed method return values" do
      interface_class = Class.new do
        include Strict::Interface

        expose(:call) { returns String }
      end
      implementation = Class.new { def call = 1 }.new

      expect do
        interface_class.new(implementation).call
      end.to raise_error(Strict::MethodReturnError) { |error| expect(error.value).to eq(1) }
    end
  end

  describe "configuration" do
    it "nests and restores overrides in the current execution context" do
      original_sample_rate = described_class.configuration.sample_rate

      described_class.with_overrides(sample_rate: 0) do
        expect(described_class.configuration.sample_rate).to eq(0)
        described_class.with_overrides(sample_rate: 0.5) do
          expect(described_class.configuration.sample_rate).to eq(0.5)
        end
        expect(described_class.configuration.sample_rate).to eq(0)
      end

      expect(described_class.configuration.sample_rate).to eq(original_sample_rate)
    end

    it "restores the previous override after an error" do
      described_class.with_overrides(sample_rate: 0) do
        expect do
          described_class.with_overrides(sample_rate: 0.5) do
            raise "restore the override"
          end
        end.to raise_error(RuntimeError, "restore the override")

        expect(described_class.configuration.sample_rate).to eq(0)
      end
    end

    it "does not inherit overrides in a new fiber" do
      original_sample_rate = described_class.configuration.sample_rate

      fiber_sample_rate = described_class.with_overrides(sample_rate: 0) do
        Fiber.new { described_class.configuration.sample_rate }.resume
      end

      expect(fiber_sample_rate).to eq(original_sample_rate)
    end

    it "does not inherit overrides in a new thread" do
      original_sample_rate = described_class.configuration.sample_rate

      thread_sample_rate = described_class.with_overrides(sample_rate: 0) do
        Thread.new { described_class.configuration.sample_rate }.value
      end

      expect(thread_sample_rate).to eq(original_sample_rate)
    end

    it "isolates overrides from application execution-context storage" do
      global_configuration = described_class.configuration
      application_configuration = Object.new
      original_application_configuration = Thread.current[:configuration]
      Thread.current[:configuration] = application_configuration

      begin
        expect(described_class.configuration).to be(global_configuration)
        expect(described_class.configure { |configuration| configuration }).to be(global_configuration)

        described_class.with_overrides(sample_rate: 0) do
          expect(described_class.configuration.sample_rate).to eq(0)
          described_class.with_overrides(sample_rate: 0.5) do
            expect(described_class.configuration.sample_rate).to eq(0.5)
          end
          expect(described_class.configuration.sample_rate).to eq(0)
        end

        expect(described_class.configuration).to be(global_configuration)
        expect(Thread.current[:configuration]).to be(application_configuration)
      ensure
        Thread.current[:configuration] = original_application_configuration
      end
    end

    it "runs coercion while sampling validator calls out" do
      validator_calls = 0
      coercer_calls = 0
      validator = Object.new
      validator.define_singleton_method(:===) do |_value|
        validator_calls += 1
        false
      end
      value_class = Class.new do
        include Strict::Value

        attributes do
          value validator, coerce: ->(value) { # rubocop:disable Style/Lambda
            coercer_calls += 1
            value.to_s
          }
        end
      end

      described_class.with_overrides(sample_rate: 0) { value_class.new(value: 1) }

      expect(coercer_calls).to eq(1)
      expect(validator_calls).to eq(0)
    end

    it "samples each attribute independently while retaining coercion and defaults" do
      validations = []
      validator = lambda do |name|
        Object.new.tap do |value|
          value.define_singleton_method(:===) do |_argument|
            validations << name
            true
          end
        end
      end
      random_values = [0.25, 0.75, 0.25]
      random = Object.new.extend(Random::Formatter)
      random.define_singleton_method(:rand) { random_values.shift }
      value_class = Class.new do
        include Strict::Value

        attributes do
          first validator.call(:first)
          second validator.call(:second), coerce: ->(value) { value.to_s }
          third validator.call(:third), default: "default"
        end
      end

      value = described_class.with_overrides(random: random, sample_rate: 0.5) do
        value_class.new(first: 1, second: 2)
      end

      expect(value.to_h).to eq(first: 1, second: "2", third: "default")
      expect(validations).to eq(%i[first third])
      expect(random_values).to be_empty
    end
  end

  describe "exceptions" do
    it "exposes caller-level initialization readers" do
      value_class = Class.new do
        include Strict::Value

        attributes do
          one Integer
          two String
        end
      end

      expect do
        value_class.new(one: 1, extra: true)
      end.to raise_error(Strict::InitializationError) { |error|
        expect(error).to be_a(Strict::Error)
        expect(error.remaining_attributes.to_a).to eq([:extra])
        expect(error.missing_attributes).to eq([:two])
      }
    end

    it "exposes caller-level method call and definition readers" do
      method_class = Class.new do
        include Strict::Method

        sig do
          one Integer
          two String
        end
        def call(one, two:); end
      end

      expect do
        method_class.new.call(:invalid, :extra, unknown: true)
      end.to raise_error(Strict::MethodCallError) { |error|
        expect(error.remaining_args).to eq([:extra])
        expect(error.remaining_kwargs).to eq(unknown: true)
        expect(error.missing_parameters).to eq([:two])
      }

      expect do
        Class.new do
          include Strict::Method

          sig { one Integer }
          def call(two); end
        end
      end.to raise_error(Strict::MethodDefinitionError) { |error|
        expect(error.missing_parameters.to_a).to eq([:one])
        expect(error.additional_parameters.to_a).to eq([:two])
      }
    end

    it "exposes the original invalid return value and violation" do
      returned = Object.new
      method_class = Class.new do
        include Strict::Method

        sig { returns String }
        define_method(:call) { returned }
      end

      expect do
        method_class.new.call
      end.to raise_error(Strict::MethodReturnError) { |error|
        expect(error.value).to be(returned)
        expect(error.violations.fetch(0).value).to be(returned)
      }
    end
  end
end
