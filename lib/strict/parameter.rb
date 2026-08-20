# frozen_string_literal: true

module Strict
  class Parameter < Declaration
    class << self
      private

      def coercer_supported?(coercer)
        super || coercer.respond_to?(:call)
      end
    end

    def coerce(value)
      return value unless coercer

      coercer.call(value)
    end
  end
end
