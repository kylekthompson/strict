# frozen_string_literal: true

require "strict"
require "rspec/core"
require "rspec/expectations"
require "rspec/mocks"
require "rspec/support/fuzzy_matcher"

module Strict
  module RSpec
    NO_VIOLATIONS = [].freeze
    INSTANCE_VARIABLE_GET = ::Object.instance_method(:instance_variable_get)
    private_constant :NO_VIOLATIONS
    private_constant :INSTANCE_VARIABLE_GET

    class << self
      def valid?(validator, value)
        violations(validator, value).empty?
      end

      def violations(validator, value)
        return NO_VIOLATIONS if test_value?(validator, value)
        return validator.violations(value) if Strict::DetailedValidator === validator
        return NO_VIOLATIONS if validator === value

        [Strict::Violation.new(path: [], code: :invalid, value: value, validator: validator)]
      end

      def test_value?(validator, value)
        matcher?(value) || instance_double_valid_for?(validator, value)
      end

      def matcher?(value)
        ::RSpec::Support.is_a_matcher?(value)
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

      def violation_details(violations)
        descriptions = violations.map { |violation| "  - #{violation_description(violation)}" }
        "violations:\n#{descriptions.join("\n")}"
      end

      private

      def violation_description(violation)
        location = violation.path.empty? ? "root" : violation.path.inspect

        case violation.code
        when :invalid
          "at #{location}: expected #{format(violation.validator)}, got #{format(violation.value)}"
        when :missing
          "at #{location}: expected #{format(violation.validator)}, but the value was missing"
        when :unexpected
          "at #{location}: got unexpected #{format(violation.value)}"
        end
      end

      def format(value)
        ::RSpec::Support::ObjectFormatter.format(value)
      end
    end

    module AcceptsMatchersAndDoubles
      def violations(value, configuration = Strict.configuration)
        return NO_VIOLATIONS if Strict::RSpec.test_value?(validator, value)

        super
      end
    end

    module AcceptsNestedMatchersAndDoubles
      def violations(validator, value)
        return NO_VIOLATIONS if Strict::RSpec.test_value?(validator, value)

        super
      end
    end

    module ComposableValue
      def ===(other)
        return false unless other.instance_of?(self.class)

        self.class.strict_attributes.all? do |attribute|
          expected = public_send(attribute.name)
          actual = other.public_send(attribute.name)
          ::RSpec::Support::FuzzyMatcher.values_match?(expected, actual)
        end
      end
    end

    module ExampleMethods
      def strict_double(strict_class, stubs = {})
        instance_double(strict_class, Strict::RSpec.stubs_for(strict_class, stubs))
      end
    end
  end
end

Strict::Declaration.prepend(Strict::RSpec::AcceptsMatchersAndDoubles)
Strict::Return.prepend(Strict::RSpec::AcceptsMatchersAndDoubles)
Strict::Validation.singleton_class.prepend(Strict::RSpec::AcceptsNestedMatchersAndDoubles)
Strict::Value.prepend(Strict::RSpec::ComposableValue)

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
    @violations = Strict::RSpec.violations(validator, value)
    @violations.empty?
  end

  failure_message do |validator|
    message = "expected #{validator.inspect} to validate #{value.inspect}"
    "#{message}\n\n#{Strict::RSpec.violation_details(@violations)}"
  end

  failure_message_when_negated do |validator|
    "expected #{validator.inspect} not to validate #{value.inspect}"
  end
end
