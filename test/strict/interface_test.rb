# frozen_string_literal: true

require "test_helper"

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
  end
  # rubocop:enable Lint/UnusedMethodArgument
end

describe Strict::Interface do
  before do
    @interface = Class.new do
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
      error = assert_raises(Strict::ImplementationDoesNotConformError) do
        InterfaceTest::Interface.new(InterfaceTest::BadImplementation.new)
      end

      assert_match(/first_method/, error.message)
      assert_match(/second_method/, error.message)
      assert_match(/third_method/, error.message)
    end

    it "does not raise when given a good implementation" do
      interface = InterfaceTest::Interface.new(InterfaceTest::GoodImplementation.new)

      assert_equal "1", interface.first_method(foo: 1, bar: "2")
      assert_equal 2, interface.second_method(baz: "1", bat: 2)
      assert_equal "3", interface.third_method(fizz: 1, buzz: "2")
    end

    it "raises when missing a parameter" do
      assert_raises(Strict::ImplementationDoesNotConformError) do
        @interface.new(
          Class.new do
            def call(one:); end
          end.new
        )
      end
    end

    it "raises when given an extra parameter" do
      assert_raises(Strict::ImplementationDoesNotConformError) do
        @interface.new(
          Class.new do
            def call(one:, two:, three:); end
          end.new
        )
      end
    end

    it "raises when given a non-keyword parameter" do
      assert_raises(Strict::ImplementationDoesNotConformError) do
        @interface.new(
          Class.new do
            def call(one, two:); end
          end.new
        )
      end
    end

    it "raises when missing a method" do
      assert_raises(Strict::ImplementationDoesNotConformError) do
        @interface.new(
          Class.new.new
        )
      end
    end

    it "does not raise when other methods are defined" do
      @interface.new(
        Class.new do
          def call(one:, two:); end
          def other(one:, two:); end
        end.new
      )
    end
  end

  describe ".coercer" do
    it "returns nil when coercing nil" do
      assert_nil InterfaceTest::Interface.coercer.call(nil)
    end

    it "returns the interface when passed an instance of the interface" do
      interface = InterfaceTest::Interface.new(InterfaceTest::GoodImplementation.new)
      assert_equal interface, InterfaceTest::Interface.coercer.call(interface)
    end

    it "attempts to instantiate the interface otherwise" do
      interface = InterfaceTest::Interface.coercer.call(InterfaceTest::GoodImplementation.new)
      assert_equal InterfaceTest::Interface, interface.class
      assert_equal InterfaceTest::GoodImplementation, interface.implementation.class
      assert_equal "1", interface.first_method(foo: 1, bar: "2")

      assert_raises(Strict::ImplementationDoesNotConformError) do
        InterfaceTest::Interface.coercer.call(InterfaceTest::BadImplementation.new)
      end
    end
  end

  describe "exposed methods" do
    it "behaves like a Strict::Method" do
      interface = InterfaceTest::Interface.new(InterfaceTest::GoodImplementation.new)

      assert_raises(Strict::MethodCallError) do
        interface.first_method(foo: "1", bar: "2")
      end
    end
  end
end
