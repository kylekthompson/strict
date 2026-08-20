# frozen_string_literal: true

module Strict
  module DetailedValidator
    def ===(value)
      violations(value).empty?
    end
  end
end
