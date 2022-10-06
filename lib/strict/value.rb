# frozen_string_literal: true

module Strict
  module Value
    def self.included(mod)
      mod.extend(Reader::Attributes)
    end

    def with(**attributes)
      self.class.new(**to_h.merge(attributes))
    end

    def eql?(other)
      self.class.equal?(other.class) && to_h.eql?(other.to_h)
    end
    alias == eql?

    def hash
      [self.class, to_h].hash
    end
  end
end
