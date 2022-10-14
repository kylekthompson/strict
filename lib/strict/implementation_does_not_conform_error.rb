# frozen_string_literal: true

module Strict
  class ImplementationDoesNotConformError < Error
    attr_reader :interface, :receiver, :missing_methods, :invalid_method_definitions

    def initialize(interface:, receiver:, missing_methods:, invalid_method_definitions:)
      super(message_from(interface:, receiver:, missing_methods:, invalid_method_definitions:))

      @interface = interface
      @receiver = receiver
      @missing_methods = missing_methods
      @invalid_method_definitions = invalid_method_definitions
    end

    private

    def message_from(interface:, receiver:, missing_methods:, invalid_method_definitions:)
      details = [
        missing_methods_message_from(missing_methods),
        invalid_method_definitions_message_from(invalid_method_definitions)
      ].compact.join("\n")

      case receiver
      when ::Class, ::Module
        "#{receiver}'s implementation of #{interface} does not conform:\n#{details}"
      else
        "#{receiver.class}'s implementation of #{interface} does not conform:\n#{details}"
      end
    end

    def missing_methods_message_from(missing_methods)
      return nil unless missing_methods

      details = missing_methods.map do |method_name|
        "    - #{method_name}"
      end.join("\n")

      "  Some methods exposed in the interface were not defined in the implementation:\n#{details}"
    end

    def invalid_method_definitions_message_from(invalid_method_definitions)
      return nil if invalid_method_definitions.empty?

      methods_details = invalid_method_definitions.map do |name, invalid_method_definition|
        method_details = [
          missing_parameters_message_from(invalid_method_definition.fetch(:missing_parameters)),
          additional_parameters_message_from(invalid_method_definition.fetch(:additional_parameters)),
          non_keyword_parameters_message_from(invalid_method_definition.fetch(:non_keyword_parameters))
        ].compact.join("\n")

        "    #{name}:\n#{method_details}"
      end.join("\n")

      "  Some methods defined in the implementation did not conform to their interface:\n#{methods_details}"
    end

    def missing_parameters_message_from(missing_parameters)
      return nil unless missing_parameters.any?

      details = missing_parameters.map do |parameter_name|
        "        - #{parameter_name}"
      end.join("\n")

      "      Some parameters were expected, but were not in the parameter list:\n#{details}"
    end

    def additional_parameters_message_from(additional_parameters)
      return nil unless additional_parameters.any?

      details = additional_parameters.map do |parameter_name|
        "        - #{parameter_name}"
      end.join("\n")

      "      Some parameters were not expected, but were in the parameter list:\n#{details}"
    end

    def non_keyword_parameters_message_from(non_keyword_parameters)
      return nil unless non_keyword_parameters.any?

      details = non_keyword_parameters.map do |parameter_name|
        "        - #{parameter_name}"
      end.join("\n")

      "      Some parameters were not keywords, but only keywords are supported:\n#{details}"
    end
  end
end
