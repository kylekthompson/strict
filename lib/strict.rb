# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module Strict
  ISSUE_TRACKER = "https://github.com/kylekthompson/strict/issues"
end
