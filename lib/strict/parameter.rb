# frozen_string_literal: true

module Strict
  class Parameter < Declaration
    def coerce(value)
      return value unless coercer

      coercer.call(value)
    end
  end
end
