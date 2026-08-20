# frozen_string_literal: true

module Strict
  class Declaration
    NOT_PROVIDED = ::Object.new.freeze
    DECLARATION_NAME = /\A[a-z_][a-zA-Z0-9_]*[!?]?\z/
    private_constant :DECLARATION_NAME

    class << self
      def make(
        name,
        validator = Validators::Anything.instance,
        coerce: validator.respond_to?(:coercer) ? validator.coercer : false,
        **defaults
      )
        validate_name!(name)
        validate_defaults!(**defaults)
        validate_coercer!(coerce)

        new(
          name: name.to_sym,
          validator: validator,
          default_generator: make_default_generator(**defaults),
          coercer: coerce
        )
      end

      private

      def validate_name!(name)
        supported_type = name.is_a?(::String) || name.is_a?(::Symbol)
        return if supported_type && DECLARATION_NAME.match?(name.to_s)

        raise ArgumentError, "Declaration name must be a supported String or Symbol, got #{name.inspect}"
      end

      def validate_defaults!(**defaults)
        unless valid_defaults?(**defaults)
          raise ArgumentError, "Only one of 'default', 'default_value', or 'default_generator' can be provided"
        end

        validate_default_generator!(**defaults)
      end

      def valid_defaults?(default: NOT_PROVIDED, default_value: NOT_PROVIDED, default_generator: NOT_PROVIDED)
        defaults_provided = [default, default_value, default_generator].count do |default_option|
          !default_option.equal?(NOT_PROVIDED)
        end

        defaults_provided <= 1
      end

      def validate_default_generator!(default_generator: NOT_PROVIDED, **)
        return if default_generator.equal?(NOT_PROVIDED) || default_generator.respond_to?(:call)

        raise ArgumentError, "default_generator must be callable, got #{default_generator.inspect}"
      end

      def validate_coercer!(coercer)
        return if coercer_supported?(coercer)

        raise ArgumentError, "Unsupported coercer: #{coercer.inspect}"
      end

      def coercer_supported?(coercer)
        coercer.equal?(false)
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
      @detailed_validator = DetailedValidator === validator
    end

    def optional?
      @optional
    end

    def valid?(value, configuration = Strict.configuration)
      violations(value, configuration).empty?
    end

    def violations(value, configuration = Strict.configuration)
      return Validation::NONE unless configuration.validate?
      return validator.violations(value) if @detailed_validator
      return Validation::NONE if validator === value

      Validation.invalid(validator, value)
    end
  end
end
