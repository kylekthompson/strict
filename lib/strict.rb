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
  end
end
