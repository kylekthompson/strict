# frozen_string_literal: true

module Strict
  class Attribute < Declaration
    attr_reader :instance_variable

    def initialize(name:, validator:, default_generator:, coercer:)
      super
      @instance_variable = "@#{name.to_s.chomp('!').chomp('?')}"
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
