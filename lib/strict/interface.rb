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

      def expose(method_name, &)
        method_name = method_name.to_sym
        configuration = Methods::Dsl.run(&)
        verifiable_method = Methods::VerifiableMethod.for_interface(
          owner: self,
          name: method_name,
          configuration: configuration
        )

        strict_instance_methods[method_name] = verifiable_method
        strict_method_wrapper(self).wrap(verifiable_method, invocation_target: :implementation)
      end
    end
  end
end
