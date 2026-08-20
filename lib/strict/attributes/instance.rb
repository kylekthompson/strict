# frozen_string_literal: true

module Strict
  module Attributes
    module Instance
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def initialize(**attributes)
        initializable_class = self.class
        configuration = Strict.configuration
        invalid_attributes = nil
        missing_attributes = nil

        initializable_class.strict_attributes.each do |attribute|
          if attributes.key?(attribute.name)
            value = attributes.delete(attribute.name)
          elsif attribute.optional?
            value = attribute.default_generator.call
          else
            missing_attributes ||= []
            missing_attributes << attribute.name
            next
          end

          value = attribute.coerce(value, for_class: initializable_class)
          if attribute.valid?(value, configuration)
            instance_variable_set(attribute.instance_variable, value)
          else
            invalid_attributes ||= {}
            invalid_attributes[attribute] = value
          end
        end

        return if attributes.empty? && invalid_attributes.nil? && missing_attributes.nil?

        raise InitializationError.new(
          initializable_class: initializable_class,
          remaining_attributes: Set.new(attributes.keys),
          invalid_attributes: invalid_attributes,
          missing_attributes: missing_attributes
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
