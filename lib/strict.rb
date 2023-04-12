# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module Strict
  ISSUE_TRACKER = "https://github.com/kylekthompson/strict/issues"

  class << self
    def configuration
      thread_configuration || global_configuration
    end

    def configure
      raise Strict::Error, "cannot reconfigure overridden configuration" if overridden?

      yield(configuration)
    end

    def with_overrides(**overrides)
      original_thread_configuration = thread_configuration

      begin
        self.thread_configuration = Strict::Configuration.new(**configuration.to_h.merge(overrides))
        yield
      ensure
        self.thread_configuration = original_thread_configuration
      end
    end

    private

    def overridden?
      !!thread_configuration
    end

    def thread_configuration
      Thread.current[:configuration]
    end

    def thread_configuration=(configuration)
      Thread.current[:configuration] = configuration
    end

    def global_configuration
      @global_configuration ||= Strict::Configuration.new
    end
  end
end
