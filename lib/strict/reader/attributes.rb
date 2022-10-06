# frozen_string_literal: true

module Strict
  module Reader
    module Attributes
      def attributes(&block)
        block ||= -> {}
        configuration = Strict::Attributes::Dsl.run(&block)
        include Module.new(configuration)
        include Strict::Attributes::Initializable
        extend Strict::Attributes::Configured
      end
    end
  end
end
