# frozen_string_literal: true

module Strict
  module Attributes
    module Initializable
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def initialize(**attributes)
        remaining_attributes = Set.new(attributes.keys)
        invalid_attributes = nil
        missing_attributes = nil

        self.class.strict_attributes_recipe.attributes.each do |attribute|
          if remaining_attributes.delete?(attribute.name)
            value = attributes.fetch(attribute.name)
          elsif attribute.optional?
            value = attribute.default_generator.call
          else
            missing_attributes ||= []
            missing_attributes << attribute.name
            next
          end

          value = attribute.coerce(value, for_class: self.class)
          if attribute.valid?(value)
            instance_variable_set(attribute.instance_variable, value)
          else
            invalid_attributes ||= {}
            invalid_attributes[attribute] = value
          end
        end

        return if remaining_attributes.none? && invalid_attributes.nil? && missing_attributes.nil?

        raise InitializationError.new(
          initializable_class: self.class,
          remaining_attributes:,
          invalid_attributes:,
          missing_attributes:
        )
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    end
  end
end
