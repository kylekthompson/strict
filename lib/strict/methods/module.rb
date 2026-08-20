# frozen_string_literal: true

module Strict
  module Methods
    class Module < ::Module
      def wrap(verifiable_method, invocation_target: :super)
        case invocation_target
        when :super
          wrap_super(verifiable_method)
        when :implementation
          wrap_implementation(verifiable_method)
        else
          raise ArgumentError, "Unknown invocation target: #{invocation_target.inspect}"
        end
      end

      private

      def wrap_super(verifiable_method)
        define_method verifiable_method.name do |*args, **kwargs, &block|
          configuration = Strict.configuration
          verified_arguments = verifiable_method.verify_parameters!(args, kwargs, configuration)
          args, kwargs = verified_arguments if verified_arguments

          super(*args, **kwargs, &block).tap do |value|
            verifiable_method.verify_returns!(value, configuration)
          end
        end
      end

      def wrap_implementation(verifiable_method)
        method_name = verifiable_method.name
        define_method method_name do |*args, **kwargs, &block|
          configuration = Strict.configuration
          verified_arguments = verifiable_method.verify_parameters!(args, kwargs, configuration)
          args, kwargs = verified_arguments if verified_arguments

          implementation.public_send(method_name, *args, **kwargs, &block).tap do |value|
            verifiable_method.verify_returns!(value, configuration)
          end
        end
      end
    end
  end
end
