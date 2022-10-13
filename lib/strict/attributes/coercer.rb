# frozen_string_literal: true

module Strict
  module Attributes
    class Coercer
      attr_reader :attributes_class

      def initialize(attributes_class)
        @attributes_class = attributes_class
      end

      def call(value)
        return value if value.nil? || !value.respond_to?(:to_h)

        coerce(value.to_h)
      end

      private

      NOT_PROVIDED = ::Object.new.freeze

      def coerce(hash)
        attributes_class.new(
          **attributes_class.strict_attributes.each_with_object({}) do |attribute, attributes|
            value = hash.fetch(attribute.name) { hash.fetch(attribute.name.to_s, NOT_PROVIDED) }
            attributes[attribute.name] = value unless value.equal?(NOT_PROVIDED)
          end
        )
      end
    end
  end
end
