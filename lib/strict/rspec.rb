# frozen_string_literal: true

require "strict"
require "rspec/core"
require "rspec/expectations"
require "rspec/mocks"

module Strict
  module RSpec
    INSTANCE_VARIABLE_GET = ::Object.instance_method(:instance_variable_get)
    private_constant :INSTANCE_VARIABLE_GET

    class << self
      def valid?(validator, value)
        validator === value || instance_double_valid_for?(validator, value)
      end

      def instance_double_valid_for?(validator, value)
        return false unless ::RSpec::Mocks::InstanceVerifyingDouble === value
        return false unless ::Module === validator

        doubled_module = INSTANCE_VARIABLE_GET.bind_call(value, :@doubled_module).target
        doubled_module && !!(doubled_module <= validator)
      end

      def stubs_for(strict_class, stubs)
        return stubs unless strict_class.respond_to?(:strict_interface_conformance)

        strict_class.strict_instance_methods.to_h { |name, _method| [name, nil] }.merge(stubs)
      end
    end

    module ValidatesInstanceDoubles
      def valid?(value, configuration = Strict.configuration)
        super || Strict::RSpec.instance_double_valid_for?(validator, value)
      end
    end

    module ExampleMethods
      def strict_double(strict_class, stubs = {})
        instance_double(strict_class, Strict::RSpec.stubs_for(strict_class, stubs))
      end
    end
  end
end

Strict::Declaration.prepend(Strict::RSpec::ValidatesInstanceDoubles)
Strict::Return.prepend(Strict::RSpec::ValidatesInstanceDoubles)

RSpec.configure do |config|
  config.include Strict::RSpec::ExampleMethods
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
    Strict::RSpec.valid?(validator, value)
  end

  failure_message do |validator|
    "expected #{validator.inspect} to validate #{value.inspect}"
  end

  failure_message_when_negated do |validator|
    "expected #{validator.inspect} not to validate #{value.inspect}"
  end
end
