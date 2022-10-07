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

      include ::Strict::Dsl::Validatable

      attr_reader :__strict_dsl_internal_parameters, :__strict_dsl_internal_returns

      def initialize
        @__strict_dsl_internal_parameters = {}
        @__strict_dsl_internal_returns = ::Strict::Return.make
      end

      def returns(*args, **kwargs)
        self.__strict_dsl_internal_returns = ::Strict::Return.make(*args, **kwargs)
        nil
      end

      def strict_parameter(*args, **kwargs)
        parameter = ::Strict::Parameter.make(*args, **kwargs)
        __strict_dsl_internal_parameters[parameter.name] = parameter
        nil
      end

      def method_missing(name, *args, **kwargs)
        if respond_to_missing?(name)
          strict_parameter(name, *args, **kwargs)
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
