# frozen_string_literal: true

require "strict"
require "rspec/core"
require "rspec/expectations"
require "rspec/mocks"

module Strict
  module RSpec
  end
end

RSpec::Matchers.define :conform_to do |interface|
  match do |implementation|
    @conformance_error = nil
    interface.new(implementation)
    true
  rescue Strict::ImplementationDoesNotConformError => e
    @conformance_error = e
    false
  end

  failure_message do |implementation|
    "expected #{implementation.inspect} to conform to #{interface.inspect}\n\n#{@conformance_error.message}"
  end

  failure_message_when_negated do |implementation|
    "expected #{implementation.inspect} not to conform to #{interface.inspect}"
  end
end

RSpec::Matchers.define :validate do |value|
  match do |validator|
    validator === value
  end

  failure_message do |validator|
    "expected #{validator.inspect} to validate #{value.inspect}"
  end

  failure_message_when_negated do |validator|
    "expected #{validator.inspect} not to validate #{value.inspect}"
  end
end
