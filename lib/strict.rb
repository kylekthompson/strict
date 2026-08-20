# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/strict/rspec.rb")
loader.setup

module Strict
  ISSUE_TRACKER = "https://github.com/kylekthompson/strict/issues"

  class << self
    def configuration
      execution_context_override || global_configuration
    end

    def configure
      raise Strict::Error, "cannot reconfigure overridden configuration" if overridden?

      yield(configuration)
    end

    def with_overrides(**overrides)
      original_override = execution_context_override

      begin
        self.execution_context_override = Strict::Configuration.new(**configuration.to_h, **overrides)
        yield
      ensure
        self.execution_context_override = original_override
      end
    end

    private

    def overridden?
      !!execution_context_override
    end

    def execution_context_override
      Thread.current[:__strict_configuration_override]
    end

    def execution_context_override=(configuration)
      Thread.current[:__strict_configuration_override] = configuration
    end

    def global_configuration
      @global_configuration ||= Strict::Configuration.new
    end
  end
end
