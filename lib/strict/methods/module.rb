# frozen_string_literal: true

module Strict
  module Methods
    class Module < ::Module
      attr_reader :verifiable_method

      def initialize(verifiable_method)
        super()

        @verifiable_method = verifiable_method
        define_method verifiable_method.name do |*args, **kwargs, &block|
          configuration = Strict.configuration
          verified_arguments = verifiable_method.verify_parameters!(args, kwargs, configuration)
          args, kwargs = verified_arguments if verified_arguments

          super(*args, **kwargs, &block).tap do |value|
            verifiable_method.verify_returns!(value, configuration)
          end
        end
      end

      def inspect
        "#<#{self.class} (#{verifiable_method.name})>"
      end
    end
  end
end
