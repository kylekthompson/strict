# frozen_string_literal: true

module Strict
  module Dsl
    module Coercible
      # rubocop:disable Naming/MethodName

      def ToArray(with: nil) = ::Strict::Coercers::Array.new(with)
      def ToHash(with_keys: nil, with_values: nil) = ::Strict::Coercers::Hash.new(with_keys, with_values)

      # rubocop:enable Naming/MethodName
    end
  end
end
