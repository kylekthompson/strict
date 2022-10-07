# frozen_string_literal: true

module Strict
  class Parameter
    NOT_PROVIDED = ::Object.new.freeze

    class << self
      def make(name, validator = Validators::Anything.instance, coerce: false, **defaults)
        unless valid_defaults?(**defaults)
          raise ArgumentError, "Only one of 'default', 'default_value', or 'default_generator' can be provided"
        end

        new(name: name.to_sym, validator:, default_generator: make_default_generator(**defaults), coercer: coerce)
      end

      private

      def valid_defaults?(default: NOT_PROVIDED, default_value: NOT_PROVIDED, default_generator: NOT_PROVIDED)
        defaults_provided = [default, default_value, default_generator].count do |default_option|
          !default_option.equal?(NOT_PROVIDED)
        end

        defaults_provided <= 1
      end

      def make_default_generator(default: NOT_PROVIDED, default_value: NOT_PROVIDED, default_generator: NOT_PROVIDED)
        if !default.equal?(NOT_PROVIDED)
          default.respond_to?(:call) ? default : -> { default }
        elsif !default_value.equal?(NOT_PROVIDED)
          -> { default_value }
        elsif !default_generator.equal?(NOT_PROVIDED)
          default_generator
        else
          NOT_PROVIDED
        end
      end
    end

    attr_reader :name, :validator, :default_generator, :coercer

    def initialize(name:, validator:, default_generator:, coercer:)
      @name = name.to_sym
      @validator = validator
      @default_generator = default_generator
      @coercer = coercer
      @optional = !default_generator.equal?(NOT_PROVIDED)
    end

    def optional?
      @optional
    end

    def valid?(value)
      validator === value
    end

    def coerce(value)
      return value unless coercer

      coercer.call(value)
    end
  end
end
