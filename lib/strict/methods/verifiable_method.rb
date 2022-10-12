# frozen_string_literal: true

require "forwardable"

module Strict
  module Methods
    class VerifiableMethod # rubocop:disable Metrics/ClassLength
      extend Forwardable

      class UnknownParameterError < Error
        attr_reader :parameter_name

        def initialize(parameter_name:)
          super(message_from(parameter_name:))

          @parameter_name = parameter_name
        end

        private

        def message_from(parameter_name:)
          "Strict tried to find a parameter named #{parameter_name} but was unable. " \
            "It's likely this in an internal bug, feel free to open an issue at #{Strict::ISSUE_TRACKER} for help."
        end
      end

      def_delegator :method, :name

      attr_reader :parameters, :returns

      def initialize(method:, parameters:, returns:, instance:)
        @method = method
        @parameters = parameters
        @parameters_index = parameters.to_h { |p| [p.name, p] }
        @returns = returns
        @instance = instance
      end

      def to_s
        "#{method.owner}#{separator}#{name}"
      end

      def verify_definition!
        expected_parameters = Set.new(parameters.map(&:name))
        defined_parameters = Set.new(method.parameters.filter_map { |kind, name| name unless kind == :block })
        return if expected_parameters == defined_parameters

        missing_parameters = expected_parameters - defined_parameters
        additional_parameters = defined_parameters - expected_parameters
        raise Strict::MethodDefinitionError.new(verifiable_method: self, missing_parameters:, additional_parameters:)
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/BlockLength
      # TODO(kkt): clean this up- it's late, though, and the tests are passing
      def verify_parameters!(*args, **kwargs)
        invalid_parameters = nil
        missing_parameters = nil

        positional_arguments = []
        keyword_arguments = {}

        # TODO(kkt): doesn't handle oddly sorted optional positional parameters like def foo(opt = nil, req)
        method.parameters.each do |kind, name|
          case kind
          when POSITIONAL
            parameter_kind = :positional
            value = args.any? ? args.shift : NOT_PROVIDED
          when REST
            parameter_kind = :rest
            value = [*args]
            args.clear
          when KEYWORD
            parameter_kind = :keyword
            value = kwargs.key?(name) ? kwargs.delete(name) : NOT_PROVIDED
          when KEYREST
            parameter_kind = :keyrest
            value = { **kwargs }
            kwargs.clear
          end
          next unless parameter_kind

          parameter = parameter_named!(name)
          if value.equal?(NOT_PROVIDED) && parameter.optional?
            value = parameter.default_generator.call
          elsif value.equal?(NOT_PROVIDED)
            missing_parameters ||= []
            missing_parameters << parameter.name
            next
          end

          value = parameter.coerce(value)
          if parameter.valid?(value)
            case parameter_kind
            when :positional
              positional_arguments << value
            when :rest
              positional_arguments.concat(value)
            when :keyword
              keyword_arguments[name] = value
            when :keyrest
              keyword_arguments.merge!(value)
            end
          else
            invalid_parameters ||= {}
            invalid_parameters[parameter] = value
          end
        end

        if args.empty? && kwargs.empty? && invalid_parameters.nil? && missing_parameters.nil?
          [positional_arguments, keyword_arguments]
        else
          raise Strict::MethodCallError.new(
            verifiable_method: self,
            remaining_args: args,
            remaining_kwargs: kwargs,
            invalid_parameters:,
            missing_parameters:
          )
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/BlockLength

      def verify_returns!(value)
        value = returns.coerce(value)
        return if returns.valid?(value)

        raise Strict::MethodReturnError.new(verifiable_method: self, value:)
      end

      private

      POSITIONAL = Set.new(%i[req opt])
      private_constant :POSITIONAL
      REST = :rest
      private_constant :REST
      KEYWORD = Set.new(%i[keyreq key])
      private_constant :KEYWORD
      KEYREST = :keyrest
      private_constant :KEYREST
      NOT_PROVIDED = ::Object.new.freeze
      private_constant :NOT_PROVIDED

      attr_reader :method, :parameters_index

      def instance?
        @instance
      end

      def separator
        instance? ? "#" : "."
      end

      def parameter_named!(name)
        parameters_index.fetch(name) { raise UnknownParameterError.new(parameter_name: name) }
      end
    end
  end
end
