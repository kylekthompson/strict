# frozen_string_literal: true

require "test_helper"

describe Strict::Method do
  it "supports a mix of positional and keyword parameters" do
    instance = Class.new do
      extend Strict::Method

      sig do
        one Integer
        two Float
      end
      def call(one, two:); end
    end.new

    assert_nil instance.call(1, two: 2.2)
  end

  it "supports rest parameters" do
    instance = Class.new do
      extend Strict::Method

      sig do
        one Integer
        rest Array
        two Float
        keyrest Hash
        returns Array
      end
      def call(one, *rest, two:, **keyrest)
        [one, rest, two, keyrest]
      end
    end.new

    assert_equal [1, [2, 3], 2.2, { other: 1 }], instance.call(1, 2, 3, two: 2.2, other: 1)
  end

  it "does not validate blocks, but passes them through" do
    instance = Class.new do
      extend Strict::Method

      sig do
        one Integer
        two Integer
        returns Integer
      end
      def call(one, two:, &block)
        one + two + block.call
      end
    end.new

    assert_equal 6, instance.call(1, two: 2) { 3 }
  end

  it "coerces arguments" do
    instance = Class.new do
      extend Strict::Method

      sig do
        one Integer, coerce: ->(value) { value.to_i }
        returns Integer
      end
      def call(one)
        one
      end
    end.new

    assert_equal 1, instance.call("1")
  end

  it "does not require optional parameters" do
    instance = Class.new do
      extend Strict::Method

      sig do
        one Integer, default: 1
        returns Integer
      end
      def call(one)
        one
      end
    end.new

    assert_equal 1, instance.call
  end

  it "ignores the defaults on the method itself when the sig has one" do
    instance = Class.new do
      extend Strict::Method

      sig do
        one Integer, default: 1
        returns Integer
      end
      def call(one: 2)
        one
      end
    end.new

    assert_equal 1, instance.call
  end

  it "invalidates postitional parameters" do
    instance = Class.new do
      extend Strict::Method

      sig do
        one Integer
        two Float
        three String
      end
      def call(one, two, three); end
    end.new

    assert_nil instance.call(1, 2.2, "3")

    error = assert_raises(Strict::MethodCallError) do
      instance.call(1, 2.2, 3)
    end
    assert_match(/three/, error.message)

    error = assert_raises(Strict::MethodCallError) do
      instance.call(1, 2.2)
    end
    assert_match(/three/, error.message)

    error = assert_raises(Strict::MethodCallError) do
      instance.call(1, 2.2, "3", 4)
    end
    assert_match(/4/, error.message)
  end

  it "invalidates keyword parameters" do
    instance = Class.new do
      extend Strict::Method

      sig do
        one Integer
        two Float
        three String
      end
      def call(one:, two:, three:); end
    end.new

    assert_nil instance.call(one: 1, two: 2.2, three: "3")

    error = assert_raises(Strict::MethodCallError) do
      instance.call(one: 1, two: 2.2, three: 3)
    end
    assert_match(/three/, error.message)

    error = assert_raises(Strict::MethodCallError) do
      instance.call(one: 1, two: 2.2)
    end
    assert_match(/three/, error.message)

    error = assert_raises(Strict::MethodCallError) do
      instance.call(one: 1, two: 2.2, three: "3", four: 4)
    end
    assert_match(/four/, error.message)
  end

  it "invalidates return values" do
    instance = Class.new do
      extend Strict::Method

      sig do
        one Anything()
        returns String
      end
      def call(one)
        one
      end
    end.new

    assert_equal "1", instance.call("1")

    error = assert_raises(Strict::MethodReturnError) do
      instance.call(1)
    end
    assert_match(/1/, error.message)
  end

  it "ensures sigs align with methods" do
    assert_raises(Strict::MethodDefinitionError) do
      Class.new do
        extend Strict::Method

        sig do
          one Anything()
        end
        def call(one, two)
          one + two
        end
      end
    end

    assert_raises(Strict::MethodDefinitionError) do
      Class.new do
        extend Strict::Method

        sig do
          one Anything()
          two Anything()
        end
        def call(one)
          one
        end
      end
    end
  end

  describe "instance methods" do
    it "only strictly validates methods declared with a sig" do
      klass = Class.new do
        extend Strict::Method

        def sigless(baz, bat)
          baz + bat
        end

        sig do
          baz Integer
          bat Integer
          returns Integer
        end
        def sigged(baz, bat)
          baz + bat
        end
      end
      instance = klass.new

      assert_empty klass.strict_class_methods.keys
      assert_equal [:sigged], klass.strict_instance_methods.keys
      assert_equal 3, instance.sigless(1, 2)
      assert_equal "12", instance.sigless("1", "2")

      assert_equal 3, instance.sigged(1, 2)
      assert_raises(Strict::MethodCallError) do
        assert_equal "12", instance.sigged("1", "2")
      end
    end
  end

  describe "self. class methods" do
    it "only strictly validates methods declared with a sig" do
      klass = Class.new do
        extend Strict::Method

        def self.sigless(baz, bat)
          baz + bat
        end

        sig do
          baz Integer
          bat Integer
          returns Integer
        end
        def self.sigged(baz, bat)
          baz + bat
        end
      end

      assert_equal [:sigged], klass.strict_class_methods.keys
      assert_empty klass.strict_instance_methods.keys
      assert_equal 3, klass.sigless(1, 2)
      assert_equal "12", klass.sigless("1", "2")

      assert_equal 3, klass.sigged(1, 2)
      assert_raises(Strict::MethodCallError) do
        assert_equal "12", klass.sigged("1", "2")
      end
    end
  end

  describe "class << self methods" do
    it "only strictly validates methods declared with a sig" do
      klass = Class.new do
        extend Strict::Method

        class << self
          def sigless(baz, bat)
            baz + bat
          end

          sig do
            baz Integer
            bat Integer
            returns Integer
          end
          def sigged(baz, bat)
            baz + bat
          end
        end
      end

      assert_equal [:sigged], klass.strict_class_methods.keys
      assert_empty klass.strict_instance_methods.keys
      assert_equal 3, klass.sigless(1, 2)
      assert_equal "12", klass.sigless("1", "2")

      assert_equal 3, klass.sigged(1, 2)
      assert_raises(Strict::MethodCallError) do
        assert_equal "12", klass.sigged("1", "2")
      end
    end
  end
end
