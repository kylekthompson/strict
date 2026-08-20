# frozen_string_literal: true

module Strict
  module Interfaces
    class Conformance
      def initialize(interface)
        @interface = interface
        @method_expectations = []
      end

      def compile(verifiable_method)
        parameter_names = verifiable_method.parameters.map(&:name).freeze

        method_expectations << MethodExpectation.new(
          name: verifiable_method.name,
          parameter_names: parameter_names,
          expected_parameter_mask: (1 << parameter_names.length) - 1
        )
      end

      def verify!(receiver)
        errors = errors_for(receiver)
        return unless errors

        missing_methods, invalid_method_definitions = errors
        raise Strict::ImplementationDoesNotConformError.new(
          interface: interface,
          receiver: receiver,
          missing_methods: missing_methods,
          invalid_method_definitions: invalid_method_definitions
        )
      end

      private

      MethodExpectation = Data.define(:name, :parameter_names, :expected_parameter_mask)
      private_constant :MethodExpectation

      attr_reader :interface, :method_expectations

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def errors_for(receiver)
        missing_methods = nil
        invalid_method_definitions = nil

        method_expectations.each do |expectation|
          unless receiver.respond_to?(expectation.name)
            (missing_methods ||= []) << expectation.name
            next
          end

          invalid_definition = invalid_definition_for(expectation, receiver.method(expectation.name).parameters)
          next unless invalid_definition

          (invalid_method_definitions ||= {})[expectation.name] = invalid_definition
        end

        return unless missing_methods || invalid_method_definitions

        [missing_methods, invalid_method_definitions || {}]
      end

      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def invalid_definition_for(expectation, implementation_parameters)
        matched_parameter_mask = 0
        has_keyword_splat = false
        additional_parameters = nil
        non_keyword_parameters = nil

        implementation_parameters.each do |kind, parameter_name|
          case kind
          when :block, :rest
            next
          when :keyrest
            has_keyword_splat = true
            next
          end

          parameter_index = expectation.parameter_names.index(parameter_name)
          unless parameter_index
            (additional_parameters ||= []) << parameter_name
            next
          end

          matched_parameter_mask |= 1 << parameter_index
          (non_keyword_parameters ||= []) << parameter_name unless kind == :keyreq
        end

        missing_parameters = missing_parameters_from(expectation, matched_parameter_mask) unless has_keyword_splat
        return unless missing_parameters || additional_parameters || non_keyword_parameters

        {
          additional_parameters: additional_parameters || [],
          missing_parameters: missing_parameters || [],
          non_keyword_parameters: non_keyword_parameters || []
        }
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      def missing_parameters_from(expectation, matched_parameter_mask)
        return if matched_parameter_mask == expectation.expected_parameter_mask

        Set.new.tap do |missing_parameters|
          expectation.parameter_names.each_with_index do |parameter_name, index|
            missing_parameters << parameter_name if matched_parameter_mask.nobits?(1 << index)
          end
        end
      end
    end
  end
end
