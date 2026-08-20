# frozen_string_literal: true

module Strict
  module Value
    def self.included(mod)
      mod.extend(Reader::Attributes)
    end

    def with(**attributes)
      self.class.new(**to_h, **attributes)
    end

    def eql?(other)
      return false unless self.class.equal?(other.class)

      self.class.strict_attributes.all? do |attribute|
        public_send(attribute.name).eql?(other.public_send(attribute.name))
      end
    end
    alias == eql?

    def hash
      value_class = self.class
      components = [value_class]
      value_class.strict_attributes.each do |attribute|
        components << public_send(attribute.name)
      end
      components.hash
    end
  end
end
