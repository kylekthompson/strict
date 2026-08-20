# frozen_string_literal: true

module Strict
  module Validation
    NONE = [].freeze
    ROOT_PATH = [].freeze

    module_function

    def violations(validator, value)
      return validator.violations(value) if DetailedValidator === validator
      return NONE if validator === value

      invalid(validator, value)
    end

    def invalid(validator, value)
      [Violation.new(path: ROOT_PATH, code: :invalid, value: value, validator: validator)]
    end

    def missing(validator, path:)
      Violation.new(path: path, code: :missing, value: nil, validator: validator)
    end

    def unexpected(value, path:)
      Violation.new(path: path, code: :unexpected, value: value, validator: nil)
    end

    def prepend_path(violations, *segments)
      violations.map do |violation|
        Violation.new(
          path: segments + violation.path,
          code: violation.code,
          value: violation.value,
          validator: violation.validator
        )
      end
    end
  end
end
