# frozen_string_literal: true

module Strict
  module Method
    def self.included(mod)
      mod.extend(Strict::Method)
    end
  end
end
