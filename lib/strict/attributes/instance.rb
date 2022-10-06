# frozen_string_literal: true

module Strict
  module Attributes
    module Instance
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def initialize(**attributes)
        remaining_attributes = Set.new(attributes.keys)
        invalid_attributes = nil
        missing_attributes = nil

        self.class.strict_attributes.each do |attribute|
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

      def to_h
        self.class.strict_attributes.to_h do |attribute|
          [attribute.name, public_send(attribute.name)]
        end
      end

      def inspect
        if self.class.strict_attributes.any?
          "#<#{self.class} #{to_h.map { |key, value| "#{key}=#{value.inspect}" }.join(' ')}>"
        else
          "#<#{self.class}>"
        end
      end

      def pretty_print(pp)
        pp.object_group(self) do
          to_h.each do |key, value|
            pp.breakable
            pp.text("#{key}=")
            pp.pp(value)
          end
        end
      end
    end
  end
end
