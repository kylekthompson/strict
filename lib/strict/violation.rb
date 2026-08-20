# frozen_string_literal: true

module Strict
  Violation = Data.define(:path, :code, :value, :validator) do
    def initialize(path:, code:, value:, validator:)
      super(path: path.dup.freeze, code: code, value: value, validator: validator)
    end
  end
end
