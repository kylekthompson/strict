# frozen_string_literal: true

module Strict
  module Reader
    class Module < ::Module
      def initialize(configuration)
        super()

        const_set(Strict::Attributes::Configured::CONSTANT, configuration)
        configuration.attributes.each do |attribute|
          module_eval(
            "def #{attribute.name} = #{attribute.instance_variable}", # def name = @instance_variable
            __FILE__,
            __LINE__ - 2
          )
        end
      end
    end
  end
end
