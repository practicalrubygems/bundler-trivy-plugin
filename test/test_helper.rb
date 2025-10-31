# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "bundler/trivy/plugin"
require "bundler/trivy/scanner"
require "bundler/trivy/config"
require "bundler/trivy/scan_result"
require "bundler/trivy/vulnerability"
require "bundler/trivy/reporter"

require "minitest/autorun"
require "minitest/pride"
require "tmpdir"
require "fileutils"
require "ostruct"
require "json"

# Test helper module for shared test utilities
module TestHelper
  # Creates a temporary directory for testing
  def create_temp_dir
    Dir.mktmpdir("bundler-trivy-test-")
  end

  # Creates a sample Gemfile.lock for testing
  def create_sample_lockfile(dir)
    lockfile_content = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          rack (2.2.3)
          sinatra (2.0.8)
            rack (~> 2.0)

      PLATFORMS
        ruby

      DEPENDENCIES
        rack (~> 2.2)
        sinatra (~> 2.0)

      BUNDLED WITH
         2.3.0
    LOCKFILE

    File.write(File.join(dir, "Gemfile.lock"), lockfile_content)
  end

  # Creates a sample configuration file for testing
  def create_sample_config(dir, content = {})
    default_config = {
      "enabled" => true,
      "fail_on" => {
        "critical" => false,
        "high" => false
      },
      "output" => {
        "format" => "terminal",
        "compact" => false
      },
      "scanning" => {
        "timeout" => 120,
        "severity_filter" => %w[CRITICAL HIGH]
      },
      "ignores" => []
    }

    config = default_config.merge(content)
    File.write(File.join(dir, ".bundler-trivy.yml"), config.to_yaml)
  end

  # Mock Trivy JSON output for testing
  def mock_trivy_output(vulnerabilities = [])
    {
      "Results" => [
        {
          "Target" => "Gemfile.lock",
          "Class" => "lang-pkgs",
          "Type" => "bundler",
          "Vulnerabilities" => vulnerabilities
        }
      ]
    }.to_json
  end

  # Sample vulnerability data for testing
  def sample_vulnerability(severity: "CRITICAL", pkg_name: "rack", cve_id: "CVE-2023-12345")
    {
      "VulnerabilityID" => cve_id,
      "PkgName" => pkg_name,
      "InstalledVersion" => "2.2.3",
      "FixedVersion" => "2.2.8, 2.3.0",
      "Severity" => severity,
      "Title" => "#{pkg_name} vulnerability",
      "Description" => "Sample vulnerability description",
      "PrimaryURL" => "https://avd.aquasec.com/nvd/#{cve_id.downcase}"
    }
  end

  # Set environment variable for test, restore after block
  def with_env(key, value)
    old_value = ENV.fetch(key, nil)
    ENV[key] = value
    yield
  ensure
    if old_value.nil?
      ENV.delete(key)
    else
      ENV[key] = old_value
    end
  end

  # Cleanup environment variables after test
  def cleanup_env_vars
    %w[
      BUNDLER_TRIVY_SKIP
      BUNDLER_TRIVY_FAIL_ON_CRITICAL
      BUNDLER_TRIVY_FAIL_ON_HIGH
      BUNDLER_TRIVY_FAIL_ON_ANY
      BUNDLER_TRIVY_COMPACT
      BUNDLER_TRIVY_FORMAT
      BUNDLER_TRIVY_TIMEOUT
      BUNDLER_TRIVY_SEVERITY
      BUNDLER_TRIVY_ENV
      CI
      TRAVIS
      GITLAB_CI
      GITHUB_ACTIONS
      JENKINS_URL
    ].each { |var| ENV.delete(var) }
  end
end

# Configure Minitest
class Minitest::Test
  include TestHelper

  def setup
    cleanup_env_vars
  end

  def teardown
    cleanup_env_vars
  end
end
