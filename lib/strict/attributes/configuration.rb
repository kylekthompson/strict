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
          super(message_from(attribute_name:))

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
        @attributes = attributes
        @attributes_index = attributes.to_h { |a| [a.name, a] }
      end

      def named!(name)
        attributes_index.fetch(name) { raise UnknownAttributeError.new(attribute_name: name) }
      end

      private

      attr_reader :attributes_index
    end
  end
end
