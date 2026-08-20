# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

desc "Validate RBS signatures"
task :rbs do
  sh "bundle exec rbs -I sig validate"
end

desc "Run timing and allocation baselines"
task :benchmark do
  sh "bundle exec ruby benchmark/baseline.rb"
end

task default: %i[spec rubocop rbs]
