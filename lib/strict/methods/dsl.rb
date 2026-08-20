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
      end

      def returns(*, **)
        self.__strict_dsl_internal_returns = ::Strict::Return.make(*, **)
        nil
      end

      def strict_parameter(*, **)
        parameter = ::Strict::Parameter.make(*, **)
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
