# frozen_string_literal: true

require "spec_helper"

module InterfaceTest
  class Interface
    include Strict::Interface

    expose(:first_method) do
      foo Integer
      bar String
      returns String
    end

    expose(:second_method) do
      baz String
      bat Integer
      returns Integer
    end

    expose(:third_method) do
      fizz Integer
      buzz String
      returns String
    end

    expose(:no_params) do
      returns String
    end
  end

  # rubocop:disable Lint/UnusedMethodArgument
  class BadImplementation
    def first_method(foo, bar:, extra:, &block)
      "first_method"
    end

    def second_method(baz:)
      2
    end
  end

  class GoodImplementation
    def first_method(foo:, bar:, &block)
      "1"
    end

    def second_method(baz:, bat:)
      2
    end

    def third_method(fizz:, buzz:)
      "3"
    end

    def no_params
      "4"
    end
  end
  # rubocop:enable Lint/UnusedMethodArgument
end

RSpec.describe Strict::Interface do
  let(:interface_class) do
    Class.new do
      include Strict::Interface

      expose(:call) do
        one String
        two String
        returns String
      end
    end
  end

  let(:underscore_interface_class) do
    Class.new do
      include Strict::Interface

      expose(:call) do
        _a String
        _b String
        returns String
      end
    end
  end

  describe ".new" do
    it "raises when given a bad implementation" do
      expect do
        InterfaceTest::Interface.new(InterfaceTest::BadImplementation.new)
      end.to raise_error(Strict::ImplementationDoesNotConformError) { |error|
        expect(error.message).to include("first_method")
        expect(error.message).to include("second_method")
        expect(error.message).to include("third_method")
        expect(error.message).to include("no_params")
      }
    end

    it "preserves the conformance error payload" do
      implementation = InterfaceTest::BadImplementation.new

      expect do
        InterfaceTest::Interface.new(implementation)
      end.to raise_error(Strict::ImplementationDoesNotConformError) { |error|
        expect(error.interface).to be(InterfaceTest::Interface)
        expect(error.receiver).to be(implementation)
        expect(error.missing_methods).to eq(%i[third_method no_params])
        expect(error.invalid_method_definitions).to eq(
          first_method: {
            additional_parameters: [:extra],
            missing_parameters: [],
            non_keyword_parameters: [:foo]
          },
          second_method: {
            additional_parameters: [],
            missing_parameters: Set[:bat],
            non_keyword_parameters: []
          }
        )
      }
    end

    it "does not raise when given a good implementation" do
      interface = InterfaceTest::Interface.new(InterfaceTest::GoodImplementation.new)

      expect(interface.first_method(foo: 1, bar: "2")).to eq("1")
      expect(interface.second_method(baz: "1", bat: 2)).to eq(2)
      expect(interface.third_method(fizz: 1, buzz: "2")).to eq("3")
      expect(interface.no_params).to eq("4")
    end

    it "uses the public implementation verification API" do
      implementation = Class.new do
        def call(one:, two:) = "#{one}#{two}"
      end.new

      allow(interface_class).to receive(:verify_implementation!).and_call_original

      expect(interface_class.new(implementation).implementation).to be(implementation)
      expect(interface_class).to have_received(:verify_implementation!).with(implementation)
    end

    it "raises when missing a parameter" do
      expect do
        interface_class.new(
          Class.new do
            def call(one:); end
          end.new
        )
      end.to raise_error(Strict::ImplementationDoesNotConformError)
    end

    # rubocop:disable Naming/MethodParameterName
    it "rejects duplicate keyword names that omit an expected parameter" do
      implementation = Class.new do
        def call(_a:, _a:); end
      end.new

      expect do
        underscore_interface_class.new(implementation)
      end.to raise_error(Strict::ImplementationDoesNotConformError)
    end

    it "reports the expected parameter omitted by duplicate keyword names" do
      implementation = Class.new do
        def call(_a:, _a:, extra:); end
      end.new

      expect do
        underscore_interface_class.new(implementation)
      end.to raise_error(Strict::ImplementationDoesNotConformError) { |error|
        expect(error.invalid_method_definitions).to eq(
          call: {
            additional_parameters: [:extra],
            missing_parameters: Set[:_b],
            non_keyword_parameters: []
          }
        )
      }
    end
    # rubocop:enable Naming/MethodParameterName

    it "raises when given an extra required keyword parameter" do
      expect do
        interface_class.new(
          Class.new do
            def call(one:, two:, three:); end
          end.new
        )
      end.to raise_error(Strict::ImplementationDoesNotConformError)
    end

    it "accepts an extra optional keyword parameter" do
      implementation = Class.new do
        def call(one:, two:, three: nil) = "#{one}#{two}#{three}"
      end.new

      expect(interface_class.new(implementation).call(one: "1", two: "2")).to eq("12")
    end

    it "accepts an extra optional positional parameter" do
      implementation = Class.new do
        def call(prefix = nil, one:, two:) = "#{prefix}#{one}#{two}"
      end.new

      expect(interface_class.new(implementation).call(one: "1", two: "2")).to eq("12")
    end

    it "raises when given a non-keyword parameter" do
      expect do
        interface_class.new(
          Class.new do
            def call(one, two:); end
          end.new
        )
      end.to raise_error(Strict::ImplementationDoesNotConformError)
    end

    it "accepts an expected keyword that is optional" do
      implementation = Class.new do
        def call(one:, two: nil) = "#{one}#{two}"
      end.new

      expect(interface_class.new(implementation).call(one: "1", two: "2")).to eq("12")
    end

    it "raises when missing a method" do
      expect do
        interface_class.new(
          Class.new.new
        )
      end.to raise_error(Strict::ImplementationDoesNotConformError)
    end

    it "treats a non-public exposed method as missing" do
      implementation = Class.new do
        private

        def call(one:, two:); end
      end.new

      expect do
        interface_class.new(implementation)
      end.to raise_error(Strict::ImplementationDoesNotConformError) { |error|
        expect(error.missing_methods).to eq([:call])
        expect(error.invalid_method_definitions).to be_empty
      }
    end

    it "does not raise when other methods are defined" do
      expect do
        interface_class.new(
          Class.new do
            def call(one:, two:); end
            def other(one:, two:); end
          end.new
        )
      end.not_to raise_error
    end

    it "does not raise when keyword args are entirely splatted" do
      expect do
        interface_class.new(
          Class.new do
            def call(**kwargs); end
          end.new
        )
      end.not_to raise_error
    end

    it "does not raise when keyword args are partially splatted" do
      expect do
        interface_class.new(
          Class.new do
            def call(one:, **kwargs); end
          end.new
        )
      end.not_to raise_error
    end

    it "rejects an additional explicit parameter when keywords are splatted" do
      implementation = Class.new do
        def call(one:, three:, **kwargs); end
      end.new

      expect do
        interface_class.new(implementation)
      end.to raise_error(Strict::ImplementationDoesNotConformError) { |error|
        expect(error.invalid_method_definitions).to eq(
          call: {
            additional_parameters: [:three],
            missing_parameters: [],
            non_keyword_parameters: []
          }
        )
      }
    end

    it "does not raise when non-keyword args are entirely splatted" do
      expect do
        interface_class.new(
          Class.new do
            def call(*args, one:, two:); end
          end.new
        )
      end.not_to raise_error
    end

    it "raises when a required positional parameter precedes splatted positional arguments" do
      expect do
        interface_class.new(
          Class.new do
            def call(foo, *args, one:, two:); end
          end.new
        )
      end.to raise_error(Strict::ImplementationDoesNotConformError)
    end

    it "does not raise when non-keyword and keyword args are entirely splatted" do
      expect do
        interface_class.new(
          Class.new do
            def call(*args, **kwargs); end
          end.new
        )
      end.not_to raise_error
    end

    it "inspects singleton methods again for each receiver wrapping" do
      implementation = Object.new
      implementation.define_singleton_method(:call) { |one:, two:| one || two }

      expect { interface_class.new(implementation) }.not_to raise_error

      implementation.define_singleton_method(:call) { |one:| one }

      expect do
        interface_class.new(implementation)
      end.to raise_error(Strict::ImplementationDoesNotConformError) { |error|
        expect(error.receiver).to be(implementation)
        expect(error.invalid_method_definitions).to eq(
          call: {
            additional_parameters: [],
            missing_parameters: Set[:two],
            non_keyword_parameters: []
          }
        )
      }
    end
  end

  describe ".implemented_by?" do
    it "returns whether an adapter conforms" do
      implementation = Class.new do
        def call(one:, two: nil); end
      end.new

      expect(interface_class.implemented_by?(implementation)).to be(true)
      expect(interface_class.implemented_by?(Object.new)).to be(false)
    end
  end

  describe ".verify_implementation!" do
    it "returns nil when the adapter conforms" do
      implementation = Class.new do
        def call(one:, two:); end
      end.new

      expect(interface_class.verify_implementation!(implementation)).to be_nil
    end

    it "raises with structured details when the adapter does not conform" do
      implementation = Object.new

      expect do
        interface_class.verify_implementation!(implementation)
      end.to raise_error(Strict::ImplementationDoesNotConformError) { |error|
        expect(error.interface).to be(interface_class)
        expect(error.receiver).to be(implementation)
        expect(error.missing_methods).to eq([:call])
        expect(error.invalid_method_definitions).to be_empty
      }
    end
  end

  describe ".coercer" do
    it "returns nil when coercing nil" do
      expect(InterfaceTest::Interface.coercer.call(nil)).to be_nil
    end

    it "returns the interface when passed an instance of the interface" do
      interface = InterfaceTest::Interface.new(InterfaceTest::GoodImplementation.new)

      expect(InterfaceTest::Interface.coercer.call(interface)).to eq(interface)
    end

    it "attempts to instantiate the interface otherwise" do
      interface = InterfaceTest::Interface.coercer.call(InterfaceTest::GoodImplementation.new)

      expect(interface).to be_an_instance_of(InterfaceTest::Interface)
      expect(interface.implementation).to be_an_instance_of(InterfaceTest::GoodImplementation)
      expect(interface.first_method(foo: 1, bar: "2")).to eq("1")

      expect do
        InterfaceTest::Interface.coercer.call(InterfaceTest::BadImplementation.new)
      end.to raise_error(Strict::ImplementationDoesNotConformError)
    end

    it "automatically wraps implementations when the interface is used as a validator" do
      value_class = Class.new do
        include Strict::Value

        attributes do
          implementation InterfaceTest::Interface
        end
      end
      implementation = InterfaceTest::GoodImplementation.new

      interface = value_class.new(implementation:).implementation

      expect(interface).to be_an_instance_of(InterfaceTest::Interface)
      expect(interface.implementation).to be(implementation)
    end
  end

  describe "exposed methods" do
    it "behaves like a Strict::Method" do
      interface = InterfaceTest::Interface.new(InterfaceTest::GoodImplementation.new)

      expect do
        interface.first_method(foo: "1", bar: "2")
      end.to raise_error(Strict::MethodCallError)
    end
  end

  it "supports reserved parameter names through strict_parameter" do
    interface_class = Class.new do
      include Strict::Interface

      expose(:call) do
        strict_parameter :if, String
        returns String
      end
    end
    implementation = Class.new do
      class_eval("def call(if:); binding.local_variable_get(:if); end", __FILE__, __LINE__)
    end.new

    expect(interface_class.new(implementation).call(if: "yes")).to eq("yes")
  end

  it "keeps internal conformance reflection private" do
    expect(interface_class).not_to respond_to(:strict_interface_conformance)
  end
end
