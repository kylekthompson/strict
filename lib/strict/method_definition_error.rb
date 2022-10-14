# frozen_string_literal: true

module Strict
  class MethodDefinitionError < Error
    attr_reader :verifiable_method, :missing_parameters, :additional_parameters

    def initialize(verifiable_method:, missing_parameters:, additional_parameters:)
      super(message_from(verifiable_method:, missing_parameters:, additional_parameters:))

      @verifiable_method = verifiable_method
      @missing_parameters = missing_parameters
      @additional_parameters = additional_parameters
    end

    private

    def message_from(verifiable_method:, missing_parameters:, additional_parameters:)
      details = [
        missing_parameters_message_from(missing_parameters),
        additional_parameters_message_from(additional_parameters)
      ].compact.join("\n")

      "Defining #{verifiable_method} failed because:\n#{details}"
    end

    def missing_parameters_message_from(missing_parameters)
      return nil unless missing_parameters.any?

      details = missing_parameters.map do |parameter_name|
        "    - #{parameter_name}"
      end.join("\n")

      "  Some parameters were in the sig, but were not in the parameter list:\n#{details}"
    end

    def additional_parameters_message_from(additional_parameters)
      return nil unless additional_parameters.any?

      details = additional_parameters.map do |parameter_name|
        "    - #{parameter_name}"
      end.join("\n")

      "  Some parameters were not in the sig, but were in the parameter list:\n#{details}"
    end
  end
end
