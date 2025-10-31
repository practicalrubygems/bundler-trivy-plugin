# frozen_string_literal: true

require_relative "lib/bundler/trivy/version"

Gem::Specification.new do |spec|
  spec.name          = "bundler-trivy"
  spec.version       = Bundler::Trivy::VERSION
  spec.authors       = ["Durable Programming LLC"]
  spec.email         = ["commercial@durableprogramming.com"]

  spec.summary       = "Trivy security scanner integration for Bundler"
  spec.description   = "Automatically scans Ruby dependencies for vulnerabilities using Trivy after bundle install. " \
                       "Provides configurable security policies, CI/CD integration, and comprehensive vulnerability reporting."
  spec.homepage      = "https://github.com/durableprogramming/bundler-trivy-plugin"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/durableprogramming/bundler-trivy-plugin/issues",
    "changelog_uri" => "https://github.com/durableprogramming/bundler-trivy-plugin/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://github.com/durableprogramming/bundler-trivy-plugin",
    "homepage_uri" => "https://github.com/durableprogramming/bundler-trivy-plugin",
    "source_code_uri" => "https://github.com/durableprogramming/bundler-trivy-plugin",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*", "plugins.rb", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", "~> 2.0"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
