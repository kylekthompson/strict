# frozen_string_literal: true

module Strict
  module Union
    VARIANT_NAME = /\A[a-z][a-z0-9]*(?:_[a-z0-9]+)*\z/
    private_constant :VARIANT_NAME
    Variant = Data.define(:tag, :variant_class)
    private_constant :Variant

    def self.included(union_class)
      union_class.extend(ClassMethods)
      union_class.include(Instance)
      union_class.instance_variable_set(:@strict_union_discriminator, nil)
      union_class.instance_variable_set(:@strict_union_attributes, nil)
      union_class.instance_variable_set(:@strict_union_variant_names, {})
      union_class.instance_variable_set(:@strict_union_variants, {})
    end

    module ClassMethods # rubocop:disable Metrics/ModuleLength
      def discriminator(name)
        raise ArgumentError, "discriminator already declared for #{self}" if @strict_union_discriminator

        discriminator = name.to_sym
        strict_union_validate_attributes!(@strict_union_attributes, discriminator)
        @strict_union_discriminator = discriminator
        nil
      end

      def attributes(&definition)
        raise ArgumentError, "attributes already declared for #{self}" if @strict_union_attributes
        raise ArgumentError, "attributes must be declared before variants for #{self}" if @strict_union_variants.any?

        definition ||= -> {}
        attributes = Attributes::Dsl.run(&definition)
        strict_union_validate_attributes!(attributes, @strict_union_discriminator)
        @strict_union_attributes = attributes
        nil
      end

      def variant(name, tag: name.to_sym, &definition)
        discriminator = strict_union_discriminator!
        name = name.to_sym
        tag_key = strict_union_tag_key(tag)
        constant_name = strict_union_validate_variant!(name, tag, tag_key)
        variant_class = strict_union_build_variant(discriminator, name, tag, definition)
        strict_union_register_variant(name, tag, tag_key, constant_name, variant_class)
      end

      def coercer
        discriminator = @strict_union_discriminator
        raise ArgumentError, "declare a discriminator before using the coercer for #{self}" unless discriminator

        Unions::Coercer.new(self, discriminator:, variants: @strict_union_variants)
      end

      def ===(value)
        @strict_union_variant_names&.value?(value.class) || false
      end

      private

      def strict_union_validate_variant!(name, tag, tag_key)
        constant_name = strict_union_constant_name(name)
        raise ArgumentError, "variant #{name.inspect} already declared for #{self}" if
          @strict_union_variant_names.key?(name)
        raise ArgumentError, "tag #{tag.inspect} already declared for #{self}" if @strict_union_variants.key?(tag_key)
        raise ArgumentError, "constant #{constant_name} is already defined for #{self}" if
          const_defined?(constant_name, false)

        constant_name
      end

      def strict_union_register_variant(name, tag, tag_key, constant_name, variant_class)
        const_set(constant_name, variant_class)
        @strict_union_variant_names[name] = variant_class
        @strict_union_variants[tag_key] = Variant.new(tag:, variant_class:)
        variant_class
      end

      def strict_union_discriminator!
        @strict_union_discriminator ||
          raise(ArgumentError, "declare a discriminator before variants for #{self}")
      end

      def strict_union_build_variant(discriminator, name, tag, definition)
        variant_class = Class.new(self)
        attribute_definition = strict_union_evaluate_variant(variant_class, name, definition)
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

      # rubocop:disable Metrics/MethodLength
      def strict_union_define_variant_attributes(variant_class, discriminator, tag, attribute_definition)
        discriminator_coercer = strict_union_discriminator_coercer(discriminator, tag)
        shared_attributes = @strict_union_attributes
        variant_class.attributes do
          strict_attribute discriminator, tag, default_value: tag, coerce: discriminator_coercer
          discriminator_attribute = __strict_dsl_internal_attributes.fetch(discriminator)
          shared_attributes&.each do |attribute|
            __strict_dsl_internal_attributes[attribute.name] = attribute
          end
          instance_exec(&attribute_definition) if attribute_definition
          unless __strict_dsl_internal_attributes.fetch(discriminator).equal?(discriminator_attribute)
            ::Kernel.raise ::ArgumentError, "variants cannot redeclare discriminator #{discriminator.inspect}"
          end
        end
      end
      # rubocop:enable Metrics/MethodLength

      def strict_union_validate_attributes!(attributes, discriminator)
        return unless discriminator && attributes

        storage = Attribute.instance_variable_for(discriminator)
        conflicting_attribute = attributes.find { |attribute| attribute.instance_variable.eql?(storage) }
        return unless conflicting_attribute

        if conflicting_attribute.name.eql?(discriminator)
          raise ArgumentError, "union attributes cannot redeclare discriminator #{discriminator.inspect}"
        end

        raise ArgumentError,
              "union attributes cannot conflict with discriminator #{discriminator.inspect}: " \
              "#{conflicting_attribute.name.inspect} uses #{storage}"
      end

      def strict_union_discriminator_coercer(discriminator, tag)
        tag_key = strict_union_tag_key(tag)
        lambda do |value|
          unless strict_union_tag_key(value).eql?(tag_key)
            raise ArgumentError, "discriminator #{discriminator.inspect} must equal #{tag.inspect}"
          end

          tag
        end
      end

      def strict_union_tag_key(tag)
        unless tag.is_a?(::String) || tag.is_a?(::Symbol)
          raise ArgumentError, "variant tag must be a String or Symbol, got #{tag.inspect}"
        end

        tag.is_a?(::String) ? tag.to_sym : tag
      end

      def strict_union_constant_name(tag)
        name = tag.to_s
        unless VARIANT_NAME.match?(name)
          raise ArgumentError, "variant name must be lower snake_case, got #{name.inspect}"
        end

        name.split("_").map { |part| part.sub(/\A./, &:upcase) }.join
      end
    end # rubocop:enable Metrics/ModuleLength

    module Instance
      def initialize(...)
        raise TypeError, "cannot instantiate union #{self.class} directly; instantiate one of its variants"
      end
    end

    private_constant :ClassMethods, :Instance
  end
end
