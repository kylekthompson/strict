# frozen_string_literal: true

module Strict
  module Reader
    class Module < ::Module
      attr_reader :configuration

      def initialize(configuration)
        super()

        @configuration = configuration
        const_set(Strict::Attributes::Class::CONSTANT, configuration)
        configuration.attributes.each do |attribute|
          module_eval(
            "def #{attribute.name} = #{attribute.instance_variable}", # def name = @instance_variable
            __FILE__,
            __LINE__ - 2
          )
        end
      end

      def inspect
        "#<#{self.class} (#{configuration.attributes.map(&:name).join(', ')})>"
      end
    end
  end
end
