# frozen_string_literal: true

module Strict
  module Method
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
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

        verifiable_method = Methods::VerifiableMethod.from_method(
          method: singleton_class.instance_method(method_name),
          configuration: sig,
          instance: false
        )
        verifiable_method.verify_definition!
        strict_class_methods[method_name] = verifiable_method
        strict_method_wrapper(singleton_class).wrap(verifiable_method)
      end

      def method_added(method_name)
        super

        sig = singleton_class.instance_variable_get(:@__strict_method_internal_last_sig_configuration)
        singleton_class.instance_variable_set(:@__strict_method_internal_last_sig_configuration, nil)
        return unless sig

        verifiable_method = Methods::VerifiableMethod.from_method(
          method: instance_method(method_name),
          configuration: sig,
          instance: true
        )
        verifiable_method.verify_definition!
        strict_instance_methods[method_name] = verifiable_method
        strict_method_wrapper(self).wrap(verifiable_method)
      end
      # rubocop:enable Metrics/MethodLength

      private

      def strict_method_wrapper(owner)
        if owner.instance_variable_defined?(:@__strict_method_internal_wrapper)
          owner.instance_variable_get(:@__strict_method_internal_wrapper)
        else
          Methods::Module.new.tap do |wrapper|
            owner.instance_variable_set(:@__strict_method_internal_wrapper, wrapper)
            owner.prepend(wrapper)
          end
        end
      end
    end
  end
end
