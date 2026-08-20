# frozen_string_literal: true

module Strict
  module Unions
    class Coercer
      NOT_PROVIDED = ::Object.new.freeze
      private_constant :NOT_PROVIDED

      def initialize(union_class, discriminator:, variants:)
        @union_class = union_class
        @discriminator = discriminator
        @variants = variants
      end

      def call(value)
        return value if value.nil? || union_class === value
        return value unless value.respond_to?(:to_h)

        coerce(value.to_h)
      end

      private

      attr_reader :union_class, :discriminator, :variants

      def coerce(hash)
        tag = tag_from(hash)
        canonical_tag = tag.is_a?(String) ? tag.to_sym : tag
        variant_for(canonical_tag, original_tag: tag).coercer.call(hash.merge(discriminator => canonical_tag))
      end

      def tag_from(hash)
        tag = hash.fetch(discriminator) { hash.fetch(discriminator.to_s, NOT_PROVIDED) }
        if tag.equal?(NOT_PROVIDED)
          raise ArgumentError, "missing discriminator #{discriminator.inspect} for #{union_class}"
        end

        tag
      end

      def variant_for(tag, original_tag:)
        variants.fetch(tag)
      rescue KeyError
        expected = variants.keys.map(&:inspect).join(", ")
        raise ArgumentError,
              "unknown discriminator #{discriminator.inspect} for #{union_class}: #{original_tag.inspect}; " \
              "expected one of #{expected}"
      end
    end
  end
end
