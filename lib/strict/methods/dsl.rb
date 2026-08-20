# frozen_string_literal: true

module Strict
  module Methods
    class Dsl < BasicObject
      class << self
        def run(&)
          dsl = new
          dsl.instance_eval(&)
          ::Strict::Methods::Configuration.new(
            parameters: dsl.__strict_dsl_internal_parameters.values,
            returns: dsl.__strict_dsl_internal_returns
          )
        end
      end

      include ::Strict::Dsl::Coercible
      include ::Strict::Dsl::Validatable

      attr_reader :__strict_dsl_internal_parameters, :__strict_dsl_internal_returns

      def initialize
        @__strict_dsl_internal_parameters = {}
        @__strict_dsl_internal_returns = ::Strict::Return.make
        @__strict_dsl_internal_returns_declared = false
      end

      def returns(*, **)
        ::Kernel.raise ::ArgumentError, "Return value is already declared" if @__strict_dsl_internal_returns_declared

        self.__strict_dsl_internal_returns = ::Strict::Return.make(*, **)
        @__strict_dsl_internal_returns_declared = true
        nil
      end

      def strict_parameter(*, **)
        parameter = ::Strict::Parameter.make(*, **)
        if __strict_dsl_internal_parameters.key?(parameter.name)
          ::Kernel.raise ::ArgumentError, "Parameter #{parameter.name.inspect} is already declared"
        end

        __strict_dsl_internal_parameters[parameter.name] = parameter
        nil
      end

      def method_missing(name, *, **)
        if respond_to_missing?(name)
          strict_parameter(name, *, **)
        else
          super
        end
      end

      def respond_to_missing?(method_name, _include_private = nil)
        first_letter = method_name.to_s.each_char.first
        first_letter.eql?(first_letter.downcase)
      end

      private

      attr_writer :__strict_dsl_internal_returns
    end
  end
end
