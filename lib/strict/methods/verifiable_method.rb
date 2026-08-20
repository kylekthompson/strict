# frozen_string_literal: true

module Strict
  module Methods
    class VerifiableMethod # rubocop:disable Metrics/ClassLength
      class << self
        def from_method(method:, configuration:, instance:)
          new(
            owner: method.owner,
            name: method.name,
            invocation_parameters: method.parameters,
            configuration: configuration,
            instance: instance
          )
        end
      end

      class UnknownParameterError < Error
        attr_reader :parameter_name

        def initialize(parameter_name:)
          super(message_from(parameter_name: parameter_name))

          @parameter_name = parameter_name
        end

        private

        def message_from(parameter_name:)
          "Strict tried to find a parameter named #{parameter_name} but was unable. " \
            "It's likely this in an internal bug, feel free to open an issue at #{Strict::ISSUE_TRACKER} for help."
        end
      end

      attr_reader :name, :parameters, :returns

      def initialize(owner:, name:, invocation_parameters:, configuration:, instance:)
        @owner = owner
        @name = name
        @parameters = configuration.parameters
        @returns = configuration.returns
        @instance = instance
        compile_invocation(invocation_parameters)
      end

      def compile_invocation(invocation_parameters)
        @parameters_index = parameters.to_h { |parameter| [parameter.name, parameter] }
        @parameter_bindings = compile_parameter_bindings(invocation_parameters)
        @keyword_parameter_names = parameter_bindings.filter_map do |binding|
          binding.name if binding.kind == :keyword
        end.freeze
        @accepts_keyrest = parameter_bindings.any? { |binding| binding.kind == :keyrest }
      end
      private :compile_invocation

      def to_s
        "#{owner}#{separator}#{name}"
      end

      def verify_definition!
        expected_parameters = Set.new(parameters.map(&:name))
        defined_parameters = Set.new(parameter_bindings.map(&:name))
        return if expected_parameters == defined_parameters

        missing_parameters = expected_parameters - defined_parameters
        additional_parameters = defined_parameters - expected_parameters
        raise Strict::MethodDefinitionError.new(
          verifiable_method: self,
          missing_parameters: missing_parameters,
          additional_parameters: additional_parameters
        )
      end

      # rubocop:disable Metrics/AbcSize, Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def verify_parameters!(args, kwargs, configuration)
        invalid_parameters = nil
        missing_parameters = nil
        verified_args = nil
        verified_kwargs = nil
        positional_argument_count = args.length
        positional_index = 0

        parameter_bindings.each do |binding|
          parameter = binding.parameter || parameter_named!(binding.name)
          positional_start = positional_index
          original_value = case binding.kind
                           when :positional
                             if positional_index < positional_argument_count
                               positional_index += 1
                               args.fetch(positional_start)
                             else
                               NOT_PROVIDED
                             end
                           when :optional_positional
                             if positional_argument_count - positional_index > binding.required_after
                               positional_index += 1
                               args.fetch(positional_start)
                             else
                               NOT_PROVIDED
                             end
                           when :rest
                             count = positional_argument_count - positional_index - binding.required_after
                             count = 0 if count.negative?
                             positional_index += count
                             if positional_start.zero? && count == positional_argument_count
                               args
                             else
                               args.slice(positional_start, count)
                             end
                           when :keyword
                             kwargs.key?(binding.name) ? kwargs.fetch(binding.name) : NOT_PROVIDED
                           when :keyrest
                             keyrest_value(kwargs)
                           end

          if original_value.equal?(NOT_PROVIDED) && parameter.optional?
            value = parameter.default_generator.call
            changed = true
          elsif original_value.equal?(NOT_PROVIDED)
            missing_parameters ||= []
            missing_parameters << parameter.name
            next
          else
            value = original_value
            changed = false
          end

          value = parameter.coerce(value)
          changed ||= !value.equal?(original_value)
          if parameter.valid?(value, configuration)
            case binding.kind
            when :positional, :optional_positional
              if verified_args
                verified_args << value
              elsif changed
                verified_args = args.take(positional_start)
                verified_args << value
              end
            when :rest
              if verified_args
                verified_args.concat(value)
              elsif rest_changed?(args, positional_start, positional_index, value, parameter.coercer)
                verified_args = args.take(positional_start)
                verified_args.concat(value)
              end
            when :keyword
              if changed
                verified_kwargs ||= kwargs.dup
                verified_kwargs[binding.name] = value
              end
            when :keyrest
              if keyrest_changed?(kwargs, value, parameter.coercer)
                verified_kwargs = merge_keyrest(verified_kwargs, kwargs, value)
              end
            end
          else
            invalid_parameters ||= {}
            invalid_parameters[parameter] = value
          end
        end

        if positional_index == positional_argument_count && no_additional_keywords?(kwargs) &&
           invalid_parameters.nil? && missing_parameters.nil?
          return if verified_args.nil? && verified_kwargs.nil?

          return [verified_args || args, verified_kwargs || kwargs]
        end

        raise Strict::MethodCallError.new(
          verifiable_method: self,
          remaining_args: args.slice(positional_index, positional_argument_count - positional_index) || [],
          remaining_kwargs: remaining_kwargs_from(kwargs),
          invalid_parameters: invalid_parameters,
          missing_parameters: missing_parameters
        )
      end
      # rubocop:enable Metrics/AbcSize, Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      def verify_returns!(value, configuration)
        value = returns.coerce(value)
        return if returns.valid?(value, configuration)

        raise Strict::MethodReturnError.new(verifiable_method: self, value: value)
      end

      private

      ParameterBinding = Data.define(:kind, :name, :parameter, :required_after)
      private_constant :ParameterBinding
      PARAMETER_KINDS = {
        req: :positional,
        opt: :optional_positional,
        rest: :rest,
        keyreq: :keyword,
        key: :keyword,
        keyrest: :keyrest
      }.freeze
      private_constant :PARAMETER_KINDS
      NOT_PROVIDED = ::Object.new.freeze
      private_constant :NOT_PROVIDED

      attr_reader :owner, :parameters_index, :parameter_bindings, :keyword_parameter_names

      # rubocop:disable Metrics/MethodLength
      def compile_parameter_bindings(invocation_parameters)
        required_after = 0
        invocation_parameters.reverse_each.filter_map do |kind, name|
          compiled_kind = PARAMETER_KINDS[kind]
          next unless compiled_kind

          binding = ParameterBinding.new(
            kind: compiled_kind,
            name: name,
            parameter: parameters_index[name],
            required_after: required_after
          )
          required_after += 1 if kind == :req
          binding
        end.reverse.freeze
      end
      # rubocop:enable Metrics/MethodLength

      def keyrest_value(kwargs)
        return kwargs if keyword_parameter_names.empty?

        kwargs.except(*keyword_parameter_names)
      end

      def rest_changed?(args, start, finish, value, coercer)
        return true if coercer
        return false if value.equal?(args)
        return true unless value.length == finish - start

        value.each_index.any? { |index| !value.fetch(index).equal?(args.fetch(start + index)) }
      end

      def keyrest_changed?(kwargs, value, coercer)
        return true if coercer
        return false if value.equal?(kwargs)

        original_size = 0
        kwargs.each do |name, original_value|
          next if keyword_parameter_names.include?(name)

          original_size += 1
          return true unless value.key?(name) && value.fetch(name).equal?(original_value)
        end
        value.size != original_size
      end

      def merge_keyrest(verified_kwargs, kwargs, value)
        return value if keyword_parameter_names.empty? && !value.equal?(kwargs)
        return verified_kwargs if keyword_parameter_names.empty?

        (verified_kwargs || kwargs.dup).delete_if do |name, _value|
          !keyword_parameter_names.include?(name)
        end.merge!(value)
      end

      def no_additional_keywords?(kwargs)
        @accepts_keyrest || kwargs.none? { |name, _value| !keyword_parameter_names.include?(name) }
      end

      def remaining_kwargs_from(kwargs)
        return {} if @accepts_keyrest

        kwargs.except(*keyword_parameter_names)
      end

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
