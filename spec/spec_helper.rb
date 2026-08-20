# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "strict"

require "debug"
require "factory_bot"

Dir[File.join(__dir__, "support/**/*.rb")].each { |file| require file }
FactoryBot.find_definitions

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.order = :random
  Kernel.srand config.seed
end
