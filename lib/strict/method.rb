# frozen_string_literal: true

module Strict
  module Method
    def self.extended(mod)
      return if mod.singleton_class?

      mod.singleton_class.extend(self)
    end

    def sig(&)
      instance = singleton_class? ? self : singleton_class
      instance.instance_variable_set(:@__strict_method_internal_last_sig_configuration, Methods::Dsl.run(&))
    end

    # rubocop:disable Metrics/MethodLength
    def singleton_method_added(method_name)
      super

      sig = singleton_class.instance_variable_get(:@__strict_method_internal_last_sig_configuration)
      singleton_class.instance_variable_set(:@__strict_method_internal_last_sig_configuration, nil)
      return unless sig

      verifiable_method = Methods::VerifiableMethod.new(
        method: singleton_class.instance_method(method_name),
        parameters: sig.parameters,
        returns: sig.returns,
        instance: false
      )
      verifiable_method.verify_definition!
      singleton_class.prepend(Methods::Module.new(verifiable_method))
    end

    def method_added(method_name)
      super

      sig = singleton_class.instance_variable_get(:@__strict_method_internal_last_sig_configuration)
      singleton_class.instance_variable_set(:@__strict_method_internal_last_sig_configuration, nil)
      return unless sig

      verifiable_method = Methods::VerifiableMethod.new(
        method: instance_method(method_name),
        parameters: sig.parameters,
        returns: sig.returns,
        instance: true
      )
      verifiable_method.verify_definition!
      prepend(Methods::Module.new(verifiable_method))
    end
    # rubocop:enable Metrics/MethodLength
  end
end
