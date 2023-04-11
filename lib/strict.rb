# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module Strict
  ISSUE_TRACKER = "https://github.com/kylekthompson/strict/issues"

  class << self
    def configuration
      @configuration ||= Strict::Configuration.new
    end

    def configure
      yield(configuration)
    end

    def with_overrides(**overrides)
      original_configuration = configuration

      begin
        self.configuration = Strict::Configuration.new(**original_configuration.to_h.merge(overrides))
        yield
      ensure
        self.configuration = original_configuration
      end
    end

    private

    attr_writer :configuration
  end
end
