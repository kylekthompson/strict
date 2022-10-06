# frozen_string_literal: true

module Strict
  module Reader
    module Attributes
      def attributes(&block)
        block ||= -> {}
        recipe = Strict::Attributes::Dsl.run(&block)
        include Module.new(recipe)
        include Strict::Attributes::Initializable
        extend ClassMethods
      end
    end
  end
end
