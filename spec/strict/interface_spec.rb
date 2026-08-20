# frozen_string_literal: true

require "spec_helper"

module InterfaceTest
  class Interface
    extend Strict::Interface

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
      extend Strict::Interface

      expose(:call) do
        one String
        two String
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

    it "does not raise when given a good implementation" do
      interface = InterfaceTest::Interface.new(InterfaceTest::GoodImplementation.new)

      expect(interface.first_method(foo: 1, bar: "2")).to eq("1")
      expect(interface.second_method(baz: "1", bat: 2)).to eq(2)
      expect(interface.third_method(fizz: 1, buzz: "2")).to eq("3")
      expect(interface.no_params).to eq("4")
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

    it "raises when given an extra parameter" do
      expect do
        interface_class.new(
          Class.new do
            def call(one:, two:, three:); end
          end.new
        )
      end.to raise_error(Strict::ImplementationDoesNotConformError)
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

    it "raises when missing a method" do
      expect do
        interface_class.new(
          Class.new.new
        )
      end.to raise_error(Strict::ImplementationDoesNotConformError)
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

    it "does not raise when non-keyword args are entirely splatted" do
      expect do
        interface_class.new(
          Class.new do
            def call(*args, one:, two:); end
          end.new
        )
      end.not_to raise_error
    end

    it "raises when non-keyword args are partially splatted" do
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
  end

  describe "exposed methods" do
    it "behaves like a Strict::Method" do
      interface = InterfaceTest::Interface.new(InterfaceTest::GoodImplementation.new)

      expect do
        interface.first_method(foo: "1", bar: "2")
      end.to raise_error(Strict::MethodCallError)
    end
  end
end
