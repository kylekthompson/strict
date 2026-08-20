# frozen_string_literal: true

module Strict
  module Validation
    NONE = [].freeze
    ROOT_PATH = [].freeze

    module_function

    def violations(validator, value, path: ROOT_PATH)
      return validator.__strict_violations__(value, path: path) if validator.respond_to?(:__strict_violations__)
      return NONE if validator === value

      invalid(validator, value, path: path)
    end

    def invalid(validator, value, path: ROOT_PATH)
      [Violation.new(path: path, code: :invalid, value: value, validator: validator)]
    end
  end
end
