# frozen_string_literal: true

module Strict
  module Interface
    def self.included(mod)
      mod.include(Strict::Method)
      mod.include(Interfaces::Instance)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def coercer
        Interfaces::Coercer.new(self)
      end

      def implemented_by?(implementation)
        verify_implementation!(implementation)
        true
      rescue Strict::ImplementationDoesNotConformError
        false
      end

      def verify_implementation!(implementation)
        strict_interface_conformance.verify!(implementation)
      end

      def expose(method_name, &)
        method_name = method_name.to_sym
        configuration = Methods::Dsl.run(&)
        verifiable_method = Methods::VerifiableMethod.for_interface(
          owner: self,
          name: method_name,
          configuration: configuration
        )

        strict_instance_methods[method_name] = verifiable_method
        strict_interface_conformance.compile(verifiable_method)
        strict_method_wrapper(self).wrap(verifiable_method, invocation_target: :implementation)
      end

      private

      def strict_interface_conformance
        @strict_interface_conformance ||= Interfaces::Conformance.new(self)
      end
    end

    private_constant :ClassMethods
  end
end
