# frozen_string_literal: true

require_relative "lib/strict/version"

Gem::Specification.new do |spec|
  spec.name = "strict"
  spec.version = Strict::VERSION
  spec.authors = ["Kyle Thompson"]
  spec.email = ["me@kkt.dev"]

  spec.summary = "Strictly define a contract for your objects and methods"
  spec.homepage = "https://github.com/kylekthompson/strict"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.2"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "zeitwerk", "~> 2.6"
  spec.add_development_dependency "gem-release", "~> 2.2"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-spec-context", "~> 0.0.4"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-minitest", "~> 0.22"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
end
