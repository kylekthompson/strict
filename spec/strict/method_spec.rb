# frozen_string_literal: true

require "spec_helper"

RSpec.describe Strict::Method do
  it "supports a mix of positional and keyword parameters" do
    instance = Class.new do
      include Strict::Method

      sig do
        one Integer
        two Float
      end
      def call(one, two:); end
    end.new

    expect(instance.call(1, two: 2.2)).to be_nil
  end

  it "supports rest parameters" do
    instance = Class.new do
      include Strict::Method

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

    expect(instance.call(1, 2, 3, two: 2.2, other: 1)).to eq([1, [2, 3], 2.2, { other: 1 }])
  end

  it "does not validate blocks, but passes them through" do
    instance = Class.new do
      include Strict::Method

      sig do
        one Integer
        two Integer
        returns Integer
      end
      def call(one, two:, &block)
        one + two + block.call
      end
    end.new

    expect(instance.call(1, two: 2) { 3 }).to eq(6)
  end

  it "coerces arguments" do
    instance = Class.new do
      include Strict::Method

      sig do
        one Integer, coerce: ->(value) { value.to_i }
        returns Integer
      end
      def call(one)
        one
      end
    end.new

    expect(instance.call("1")).to eq(1)
  end

  it "does not require optional parameters" do
    instance = Class.new do
      include Strict::Method

      sig do
        one Integer, default: 1
        returns Integer
      end
      def call(one)
        one
      end
    end.new

    expect(instance.call).to eq(1)
  end

  it "ignores the defaults on the method itself when the sig has one" do
    instance = Class.new do
      include Strict::Method

      sig do
        one Integer, default: 1
        returns Integer
      end
      def call(one: 2)
        one
      end
    end.new

    expect(instance.call).to eq(1)
  end

  it "invalidates postitional parameters" do
    instance = Class.new do
      include Strict::Method

      sig do
        one Integer
        two Float
        three String
      end
      def call(one, two, three); end
    end.new

    expect(instance.call(1, 2.2, "3")).to be_nil

    expect do
      instance.call(1, 2.2, 3)
    end.to raise_error(Strict::MethodCallError, /three/)

    expect do
      instance.call(1, 2.2)
    end.to raise_error(Strict::MethodCallError, /three/)

    expect do
      instance.call(1, 2.2, "3", 4)
    end.to raise_error(Strict::MethodCallError, /4/)
  end

  it "invalidates keyword parameters" do
    instance = Class.new do
      include Strict::Method

      sig do
        one Integer
        two Float
        three String
      end
      def call(one:, two:, three:); end
    end.new

    expect(instance.call(one: 1, two: 2.2, three: "3")).to be_nil

    expect do
      instance.call(one: 1, two: 2.2, three: 3)
    end.to raise_error(Strict::MethodCallError, /three/)

    expect do
      instance.call(one: 1, two: 2.2)
    end.to raise_error(Strict::MethodCallError, /three/)

    expect do
      instance.call(one: 1, two: 2.2, three: "3", four: 4)
    end.to raise_error(Strict::MethodCallError, /four/)
  end

  it "invalidates return values" do
    instance = Class.new do
      include Strict::Method

      sig do
        one Anything()
        returns String
      end
      def call(one)
        one
      end
    end.new

    expect(instance.call("1")).to eq("1")

    expect do
      instance.call(1)
    end.to raise_error(Strict::MethodReturnError, /1/)
  end

  it "ensures sigs align with methods" do
    expect do
      Class.new do
        include Strict::Method

        sig do
          one Anything()
        end
        def call(one, two)
          one + two
        end
      end
    end.to raise_error(Strict::MethodDefinitionError)

    expect do
      Class.new do
        include Strict::Method

        sig do
          one Anything()
          two Anything()
        end
        def call(one)
          one
        end
      end
    end.to raise_error(Strict::MethodDefinitionError)
  end

  describe "instance methods" do
    it "only strictly validates methods declared with a sig" do
      klass = Class.new do
        include Strict::Method

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

      expect(klass.strict_class_methods.keys).to be_empty
      expect(klass.strict_instance_methods.keys).to eq([:sigged])
      expect(instance.sigless(1, 2)).to eq(3)
      expect(instance.sigless("1", "2")).to eq("12")

      expect(instance.sigged(1, 2)).to eq(3)
      expect { instance.sigged("1", "2") }.to raise_error(Strict::MethodCallError)
    end
  end

  describe "self. class methods" do
    it "only strictly validates methods declared with a sig" do
      klass = Class.new do
        include Strict::Method

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

      expect(klass.strict_class_methods.keys).to eq([:sigged])
      expect(klass.strict_instance_methods.keys).to be_empty
      expect(klass.sigless(1, 2)).to eq(3)
      expect(klass.sigless("1", "2")).to eq("12")

      expect(klass.sigged(1, 2)).to eq(3)
      expect { klass.sigged("1", "2") }.to raise_error(Strict::MethodCallError)
    end
  end

  describe "class << self methods" do
    it "only strictly validates methods declared with a sig" do
      klass = Class.new do
        include Strict::Method

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

      expect(klass.strict_class_methods.keys).to eq([:sigged])
      expect(klass.strict_instance_methods.keys).to be_empty
      expect(klass.sigless(1, 2)).to eq(3)
      expect(klass.sigless("1", "2")).to eq("12")

      expect(klass.sigged(1, 2)).to eq(3)
      expect { klass.sigged("1", "2") }.to raise_error(Strict::MethodCallError)
    end
  end

  it "supports reserved parameter names through strict_parameter" do
    instance = Class.new do
      include Strict::Method

      sig do
        strict_parameter :if, String
        returns String
      end
      class_eval("def call(if:); binding.local_variable_get(:if); end", __FILE__, __LINE__)
    end.new

    expect(instance.call(if: "yes")).to eq("yes")
  end
end
