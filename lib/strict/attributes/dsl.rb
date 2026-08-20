# frozen_string_literal: true

module Strict
  module Attributes
    class Dsl < BasicObject
      class << self
        def run(attributes: [], &)
          dsl = new(attributes: attributes)
          dsl.instance_eval(&)
          ::Strict::Attributes::Configuration.new(attributes: dsl.__strict_dsl_internal_attributes.values)
        end
      end

      include ::Strict::Dsl::Coercible
      include ::Strict::Dsl::Validatable

      attr_reader :__strict_dsl_internal_attributes

      def initialize(attributes:)
        @__strict_dsl_internal_attributes = attributes.to_h { |attribute| [attribute.name, attribute] }
      end

      def strict_attribute(*, **)
        attribute = ::Strict::Attribute.make(*, **)
        __strict_dsl_internal_attributes[attribute.name] = attribute
        nil
      end

      def method_missing(name, *, **)
        if respond_to_missing?(name)
          strict_attribute(name, *, **)
        else
          super
        end
      end

      def respond_to_missing?(method_name, _include_private = nil)
        first_letter = method_name.to_s.each_char.first
        first_letter.eql?(first_letter.downcase)
      end
    end
  end
end
