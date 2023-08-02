# frozen_string_literal: true

require_relative "lib/db_analyze/version"

Gem::Specification.new do |spec|
  spec.name = "db_analyze"
  spec.version = DbAnalyze::VERSION

  spec.required_ruby_version = ">= 3.1.0"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=

  spec.authors = ["Michael Lee Squires"]
  spec.email = ["michael_lee_squires@pobox.com"]
  spec.summary = "convenient utility functions"
  spec.homepage = "https://github.com/mlsquires/db_analyze"
  spec.licenses = %w[MIT]

  spec.require_paths = ["lib"]

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end

  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  spec.add_runtime_dependency "activemodel", "~> 7.0.6"
  spec.add_runtime_dependency "activesupport", "~> 7.0.6"
  spec.add_runtime_dependency "activerecord", "~> 7.0.6"
  spec.add_runtime_dependency "dotenv", "~> 2.8.1"
  spec.add_runtime_dependency "git", ">= 1.12", "< 1.14"
  spec.add_runtime_dependency "liquid", "~> 5.0.0"
  spec.add_runtime_dependency "mls_utility", "~> 0.5.1"
  spec.add_runtime_dependency "pg", "~> 1.4.5"

  spec.add_development_dependency "amazing_print", "~> 1.5.0"
  spec.add_development_dependency "bundler", "~> 2.3.14"
  spec.add_development_dependency "pry", "~> 0.14.1"
  spec.add_development_dependency "rake", "~> 13.0.6"
  spec.add_development_dependency "reek", "~> 6.1.1"
  spec.add_development_dependency "rspec", "~> 3.11.0"
  spec.add_development_dependency "rspec-core", "~> 3.11.0"
  spec.add_development_dependency "rspec-expectations", "~> 3.11.1"
  spec.add_development_dependency "rspec-mocks", "~> 3.11.1"
  spec.add_development_dependency "rspec-support", "~> 3.11.1"
  spec.add_development_dependency "rubocop", "~> 1.35.1"
  spec.add_development_dependency "standard", "~> 1.16.1"
end
