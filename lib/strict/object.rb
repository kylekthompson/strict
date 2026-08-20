# frozen_string_literal: true

module Strict
  module Object
    def self.included(mod)
      Attributes::GeneratedMethods.install_on(mod, writable: true)
    end
  end
end
