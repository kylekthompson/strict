# frozen_string_literal: true

module Strict
  class Attribute < Declaration
    class << self
      def instance_variable_for(name)
        "@#{name.to_s.delete_suffix('?').delete_suffix('!')}"
      end

      private

      def coercer_supported?(coercer)
        super || coercer.equal?(true) || coercer.is_a?(Symbol) || coercer.respond_to?(:call)
      end
    end

    attr_reader :instance_variable

    def initialize(name:, validator:, default_generator:, coercer:)
      super
      @instance_variable = self.class.instance_variable_for(self.name)
    end

    def coerce(value, for_class:)
      return value unless coercer

      case coercer
      when Symbol
        for_class.public_send(coercer, value)
      when true
        for_class.public_send("coerce_#{name}", value)
      else
        coercer.call(value)
      end
    end
  end
end
