# frozen_string_literal: true

module Strict
  module Methods
    class Module < ::Module
      attr_reader :verifiable_method

      def initialize(verifiable_method)
        super()

        @verifiable_method = verifiable_method
        define_method verifiable_method.name do |*args, **kwargs, &block|
          args, kwargs = verifiable_method.verify_parameters!(*args, **kwargs)

          super(*args, **kwargs, &block).tap do |value|
            verifiable_method.verify_returns!(value)
          end
        end
      end

      def inspect
        "#<#{self.class} (#{verifiable_method.name})>"
      end
    end
  end
end
