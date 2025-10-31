# frozen_string_literal: true

plugin 'bundler-trivy'
source "https://rubygems.org"

# Specify your gem's dependencies in bundler-trivy-plugin.gemspec
gemspec

# Additional development dependencies not in gemspec
group :development, :test do
  gem "pry", "~> 0.14"
  gem "simplecov", "~> 0.22", require: false
end
