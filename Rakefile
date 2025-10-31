# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"

# Test task
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
  t.warning = false
end

# RuboCop task
RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ["--display-cop-names"]
end

# Default task runs tests
task default: :test

# Additional tasks
namespace :test do
  desc "Run tests with coverage"
  task :coverage do
    ENV["COVERAGE"] = "true"
    Rake::Task["test"].execute
  end
end

desc "Open an IRB console with the gem loaded"
task :console do
  require "irb"
  require "bundler/trivy/plugin"
  ARGV.clear
  IRB.start
end

desc "Build and install the gem locally"
task :install_local do
  sh "gem build bundler-trivy-plugin.gemspec"
  sh "bundle plugin uninstall bundler-trivy-plugin || true"
  sh "bundle plugin install bundler-trivy-plugin --source ."
end
