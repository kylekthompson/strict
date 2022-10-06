# frozen_string_literal: true

module Strict
  module Accessor
    module Attributes
      def attributes(&block)
        block ||= -> {}
        configuration = Strict::Attributes::Dsl.run(&block)
        include Module.new(configuration)
        include Strict::Attributes::Instance
        extend Strict::Attributes::Configured
      end
    end
  end
end
