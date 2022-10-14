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

    def strict_class_methods
      instance = singleton_class? ? self : singleton_class
      if instance.instance_variable_defined?(:@__strict_method_internal_class_methods)
        instance.instance_variable_get(:@__strict_method_internal_class_methods)
      else
        instance.instance_variable_set(:@__strict_method_internal_class_methods, {})
      end
    end

    def strict_instance_methods
      instance = singleton_class? ? self : singleton_class
      if instance.instance_variable_defined?(:@__strict_method_internal_instance_methods)
        instance.instance_variable_get(:@__strict_method_internal_instance_methods)
      else
        instance.instance_variable_set(:@__strict_method_internal_instance_methods, {})
      end
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
      strict_class_methods[method_name] = verifiable_method
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
      strict_instance_methods[method_name] = verifiable_method
      prepend(Methods::Module.new(verifiable_method))
    end
    # rubocop:enable Metrics/MethodLength
  end
end
