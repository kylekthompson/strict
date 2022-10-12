# frozen_string_literal: true

module Strict
  class MethodCallError < Error
    attr_reader :verifiable_method, :remaining_args, :remaining_kwargs, :invalid_parameters, :missing_parameters

    def initialize(verifiable_method:, remaining_args:, remaining_kwargs:, invalid_parameters:, missing_parameters:)
      super(
        message_from(verifiable_method:, remaining_args:, remaining_kwargs:, invalid_parameters:, missing_parameters:)
      )

      @verifiable_method = verifiable_method
      @remaining_args = remaining_args
      @remaining_kwargs = remaining_kwargs
      @invalid_parameters = invalid_parameters
      @missing_parameters = missing_parameters
    end

    private

    def message_from(verifiable_method:, remaining_args:, remaining_kwargs:, invalid_parameters:, missing_parameters:)
      details = [
        invalid_parameters_message_from(invalid_parameters),
        missing_parameters_message_from(missing_parameters),
        remaining_args_message_from(remaining_args),
        remaining_kwargs_message_from(remaining_kwargs)
      ].compact.join("\n")

      "Calling #{verifiable_method} failed because:\n#{details}"
    end

    def invalid_parameters_message_from(invalid_parameters)
      return nil unless invalid_parameters

      details = invalid_parameters.map do |parameter, value|
        "    - #{parameter.name}: got #{value.inspect}, expected #{parameter.validator.inspect}"
      end.join("\n")

      "  Some arguments were invalid:\n#{details}"
    end

    def missing_parameters_message_from(missing_parameters)
      return nil unless missing_parameters

      details = missing_parameters.map do |parameter_name|
        "    - #{parameter_name}"
      end.join("\n")

      "  Some arguments were missing:\n#{details}"
    end

    def remaining_args_message_from(remaining_args)
      return nil if remaining_args.none?

      details = remaining_args.map do |arg|
        "    - #{arg.inspect}"
      end.join("\n")

      "  Additional positional arguments were provided, but not defined:\n#{details}"
    end

    def remaining_kwargs_message_from(remaining_kwargs)
      return nil if remaining_kwargs.none?

      details = remaining_kwargs.map do |key, value|
        "    - #{key}: #{value.inspect}"
      end.join("\n")

      "  Additional keyword arguments were provided, but not defined:\n#{details}"
    end
  end
end
