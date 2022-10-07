# frozen_string_literal: true

module Strict
  module Object
    def self.included(mod)
      mod.extend(Accessor::Attributes)
    end
  end
end
