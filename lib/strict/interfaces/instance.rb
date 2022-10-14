# frozen_string_literal: true

module Strict
  module Interfaces
    module Instance
      attr_reader :implementation

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def initialize(implementation)
        missing_methods = nil
        invalid_method_definitions = Hash.new do |h, k|
          h[k] = { additional_parameters: [], missing_parameters: [], non_keyword_parameters: [] }
        end

        self.class.strict_instance_methods.each do |method_name, strict_method|
          unless implementation.respond_to?(method_name)
            missing_methods ||= []
            missing_methods << method_name
            next
          end

          expected_parameters = Set.new(strict_method.parameters.map(&:name))
          defined_parameters = Set.new

          implementation.method(method_name).parameters.each do |kind, parameter_name|
            next if kind == :block

            if expected_parameters.include?(parameter_name)
              defined_parameters.add(parameter_name)
              invalid_method_definitions[method_name][:non_keyword_parameters] << parameter_name if kind != :keyreq
            else
              invalid_method_definitions[method_name][:additional_parameters] << parameter_name
            end
          end

          missing_parameters = expected_parameters - defined_parameters
          invalid_method_definitions[method_name][:missing_parameters] = missing_parameters if missing_parameters.any?
        end

        if missing_methods || !invalid_method_definitions.empty?
          raise Strict::ImplementationDoesNotConformError.new(
            interface: self.class,
            receiver: implementation,
            missing_methods: missing_methods,
            invalid_method_definitions: invalid_method_definitions
          )
        end

        @implementation = implementation
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    end
  end
end
