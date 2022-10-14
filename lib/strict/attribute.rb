# frozen_string_literal: true

module Strict
  class Attribute
    NOT_PROVIDED = ::Object.new.freeze

    class << self
      def make(name, validator = Validators::Anything.instance, coerce: false, **defaults)
        unless valid_defaults?(**defaults)
          raise ArgumentError, "Only one of 'default', 'default_value', or 'default_generator' can be provided"
        end

        new(
          name: name.to_sym,
          validator: validator,
          default_generator: make_default_generator(**defaults),
          coercer: coerce
        )
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

    attr_reader :name, :validator, :default_generator, :coercer, :instance_variable

    def initialize(name:, validator:, default_generator:, coercer:)
      @name = name.to_sym
      @validator = validator
      @default_generator = default_generator
      @coercer = coercer
      @optional = !default_generator.equal?(NOT_PROVIDED)
      @instance_variable = "@#{name.to_s.chomp('!').chomp('?')}"
    end

    def optional?
      @optional
    end

    def valid?(value)
      validator === value
    end

    def coerce(value, for_class:)
      return value unless coercer

      case coercer
      when Symbol
        for_class.public_send(coercer, value)
      when true
        for_class.public_send("coerce_#{name}", value)
      else
        coercer.call(value)
      end
    end
  end
end
