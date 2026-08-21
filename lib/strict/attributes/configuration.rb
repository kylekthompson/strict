# frozen_string_literal: true

require "forwardable"

module Strict
  module Attributes
    class Configuration
      include Enumerable
      extend Forwardable

      class UnknownAttributeError < Error
        attr_reader :attribute_name

        def initialize(attribute_name:)
          super(message_from(attribute_name: attribute_name))

          @attribute_name = attribute_name
        end

        private

        def message_from(attribute_name:)
          "Strict tried to find an attribute named #{attribute_name} but was unable. " \
            "It's likely this in an internal bug, feel free to open an issue at #{Strict::ISSUE_TRACKER} for help."
        end
      end

      def_delegator :attributes, :each

      attr_reader :attributes

      def initialize(attributes:)
        validate_instance_variables!(attributes)
        @attributes = attributes
        @attributes_index = attributes.to_h { |a| [a.name, a] }
      end

      def named!(name)
        attributes_index.fetch(name) { raise UnknownAttributeError.new(attribute_name: name) }
      end

      private

      attr_reader :attributes_index

      def validate_instance_variables!(attributes)
        attributes_by_instance_variable = {}
        attributes.each do |attribute|
          conflicting_attribute = attributes_by_instance_variable[attribute.instance_variable]
          if conflicting_attribute
            raise ArgumentError,
                  "Attribute #{attribute.name.inspect} conflicts with #{conflicting_attribute.name.inspect} " \
                  "because both use #{attribute.instance_variable}"
          end

          attributes_by_instance_variable[attribute.instance_variable] = attribute
        end
      end
    end
  end
end
