# frozen_string_literal: true

module Strict
  module Union
    VARIANT_NAME = /\A[a-z][a-z0-9]*(?:_[a-z0-9]+)*\z/
    private_constant :VARIANT_NAME

    def self.included(union_class)
      union_class.extend(ClassMethods)
      union_class.include(Instance)
      union_class.instance_variable_set(:@strict_union_discriminator, nil)
      union_class.instance_variable_set(:@strict_union_variants, {})
    end

    module ClassMethods
      def discriminator(name)
        raise ArgumentError, "discriminator already declared for #{self}" if @strict_union_discriminator

        @strict_union_discriminator = name.to_sym
        nil
      end

      def variant(name, &definition)
        discriminator = strict_union_discriminator!
        tag = name.to_sym
        constant_name = strict_union_constant_name(tag)
        raise ArgumentError, "variant #{tag.inspect} already declared for #{self}" if @strict_union_variants.key?(tag)
        raise ArgumentError, "constant #{constant_name} is already defined for #{self}" if
          const_defined?(constant_name, false)

        variant_class = strict_union_build_variant(discriminator, tag, definition || -> {})
        const_set(constant_name, variant_class)
        @strict_union_variants[tag] = variant_class
        variant_class
      end

      def coercer
        discriminator = @strict_union_discriminator
        raise ArgumentError, "declare a discriminator before using the coercer for #{self}" unless discriminator

        Unions::Coercer.new(self, discriminator:, variants: @strict_union_variants)
      end

      def ===(value)
        @strict_union_variants&.value?(value.class) || false
      end

      private

      def strict_union_discriminator!
        @strict_union_discriminator ||
          raise(ArgumentError, "declare a discriminator before variants for #{self}")
      end

      def strict_union_build_variant(discriminator, tag, definition)
        variant_class = Class.new(self)
        attribute_definition = strict_union_evaluate_variant(variant_class, tag, definition)
        variant_class.include(Strict::Value)
        strict_union_define_variant_attributes(variant_class, discriminator, tag, attribute_definition)
        variant_class.define_singleton_method(:===, ::Module.instance_method(:===))
        variant_class
      end

      def strict_union_evaluate_variant(variant_class, tag, definition)
        return unless definition

        attribute_definition = nil
        variant_class.define_singleton_method(:attributes) do |&block|
          raise ArgumentError, "attributes already declared for variant #{tag.inspect}" if attribute_definition

          attribute_definition = block || -> {}
          nil
        end
        variant_class.class_exec(&definition)
        variant_class.singleton_class.remove_method(:attributes)
        attribute_definition
      end

      def strict_union_define_variant_attributes(variant_class, discriminator, tag, attribute_definition)
        discriminator_coercer = strict_union_discriminator_coercer(discriminator, tag)
        variant_class.attributes do
          strict_attribute discriminator, tag, default_value: tag, coerce: discriminator_coercer
          discriminator_attribute = __strict_dsl_internal_attributes.fetch(discriminator)
          instance_exec(&attribute_definition) if attribute_definition
          unless __strict_dsl_internal_attributes.fetch(discriminator).equal?(discriminator_attribute)
            ::Kernel.raise ::ArgumentError, "variants cannot redeclare discriminator #{discriminator.inspect}"
          end
        end
      end

      def strict_union_discriminator_coercer(discriminator, tag)
        lambda do |value|
          canonical_value = value.is_a?(::String) ? value.to_sym : value
          unless canonical_value.eql?(tag)
            raise ArgumentError, "discriminator #{discriminator.inspect} must equal #{tag.inspect}"
          end

          tag
        end
      end

      def strict_union_constant_name(tag)
        name = tag.to_s
        unless VARIANT_NAME.match?(name)
          raise ArgumentError, "variant name must be lower snake_case, got #{name.inspect}"
        end

        name.split("_").map { |part| part.sub(/\A./, &:upcase) }.join
      end
    end

    module Instance
      def initialize(...)
        raise TypeError, "cannot instantiate union #{self.class} directly; instantiate one of its variants"
      end
    end
  end
end
