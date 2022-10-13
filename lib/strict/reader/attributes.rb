# frozen_string_literal: true

module Strict
  module Reader
    module Attributes
      def attributes(&block)
        block ||= -> {}
        configuration = Strict::Attributes::Dsl.run(&block)
        include Module.new(configuration)
        include Strict::Attributes::Instance
        extend Strict::Attributes::Class
      end
    end
  end
end
