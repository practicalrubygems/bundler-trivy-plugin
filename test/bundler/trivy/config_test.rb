# frozen_string_literal: true

require "test_helper"

module Bundler
  module Trivy
    class ConfigTest < Minitest::Test
      def setup
        super
        @temp_dir = create_temp_dir
        @original_gemfile = ENV.fetch("BUNDLE_GEMFILE", nil)
        ENV["BUNDLE_GEMFILE"] = File.join(@temp_dir, "Gemfile")
      end

      def teardown
        super
        FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
        ENV["BUNDLE_GEMFILE"] = @original_gemfile
      end

      def test_skip_scan_returns_false_by_default
        config = Config.new
        refute config.skip_scan?
      end

      def test_skip_scan_respects_env_variable
        with_env("BUNDLER_TRIVY_SKIP", "true") do
          config = Config.new
          assert config.skip_scan?
        end
      end

      def test_skip_scan_respects_config_file
        create_sample_config(@temp_dir, "enabled" => false)
        config = Config.new
        assert config.skip_scan?
      end

      def test_fail_on_critical_defaults_to_false_outside_ci
        config = Config.new
        refute config.fail_on_critical?
      end

      def test_fail_on_critical_defaults_to_true_in_ci
        with_env("CI", "true") do
          config = Config.new
          assert config.fail_on_critical?
        end
      end

      def test_fail_on_critical_respects_env_variable
        with_env("BUNDLER_TRIVY_FAIL_ON_CRITICAL", "true") do
          config = Config.new
          assert config.fail_on_critical?
        end
      end

      def test_fail_on_high_defaults_to_false
        config = Config.new
        refute config.fail_on_high?
      end

      def test_fail_on_any_defaults_to_false
        config = Config.new
        refute config.fail_on_any?
      end

      def test_compact_output_defaults_to_false_outside_ci
        config = Config.new
        refute config.compact_output?
      end

      def test_compact_output_defaults_to_true_in_ci
        with_env("CI", "true") do
          config = Config.new
          assert config.compact_output?
        end
      end

      def test_json_output_defaults_to_false
        config = Config.new
        refute config.json_output?
      end

      def test_json_output_respects_env_variable
        with_env("BUNDLER_TRIVY_FORMAT", "json") do
          config = Config.new
          assert config.json_output?
        end
      end

      def test_severity_threshold_defaults_to_critical
        config = Config.new
        assert_equal "CRITICAL", config.severity_threshold
      end

      def test_severity_filter_returns_empty_array_by_default
        config = Config.new
        assert_equal [], config.severity_filter
      end

      def test_severity_filter_from_config_file
        create_sample_config(@temp_dir, "scanning" => { "severity_filter" => %w[CRITICAL HIGH] })
        config = Config.new
        assert_equal %w[CRITICAL HIGH], config.severity_filter
      end

      def test_trivy_timeout_defaults_to_120
        config = Config.new
        assert_equal 120, config.trivy_timeout
      end

      def test_trivy_timeout_respects_env_variable
        with_env("BUNDLER_TRIVY_TIMEOUT", "300") do
          config = Config.new
          assert_equal 300, config.trivy_timeout
        end
      end

      def test_ci_environment_detection_ci_env
        with_env("CI", "true") do
          config = Config.new
          assert config.ci_environment?
        end
      end

      def test_ci_environment_detection_travis
        with_env("TRAVIS", "true") do
          config = Config.new
          assert config.ci_environment?
        end
      end

      def test_ci_environment_detection_gitlab
        with_env("GITLAB_CI", "true") do
          config = Config.new
          assert config.ci_environment?
        end
      end

      def test_ci_environment_detection_github_actions
        with_env("GITHUB_ACTIONS", "true") do
          config = Config.new
          assert config.ci_environment?
        end
      end

      def test_ci_environment_detection_jenkins
        with_env("JENKINS_URL", "https://jenkins.example.com") do
          config = Config.new
          assert config.ci_environment?
        end
      end

      def test_ci_environment_detection_none
        config = Config.new
        refute config.ci_environment?
      end

      def test_ignored_cves_defaults_to_empty_array
        config = Config.new
        assert_equal [], config.ignored_cves
      end

      def test_cve_ignored_returns_false_for_non_ignored
        config = Config.new
        refute config.cve_ignored?("CVE-2023-12345")
      end

      def test_cve_ignored_returns_true_for_ignored
        ignores = [
          { "id" => "CVE-2023-12345", "reason" => "Test ignore" }
        ]
        create_sample_config(@temp_dir, "ignores" => ignores)
        config = Config.new
        assert config.cve_ignored?("CVE-2023-12345")
      end

      def test_cve_ignored_respects_expiration_date
        ignores = [
          { "id" => "CVE-2023-12345", "reason" => "Test ignore", "expires" => "2020-01-01" }
        ]
        create_sample_config(@temp_dir, "ignores" => ignores)
        config = Config.new
        refute config.cve_ignored?("CVE-2023-12345"), "Expired ignore should not be active"
      end

      def test_cve_ignored_respects_future_expiration
        future_date = (Date.today + 30).to_s
        ignores = [
          { "id" => "CVE-2023-12345", "reason" => "Test ignore", "expires" => future_date }
        ]
        create_sample_config(@temp_dir, "ignores" => ignores)
        config = Config.new
        assert config.cve_ignored?("CVE-2023-12345"), "Future expiration should be active"
      end

      def test_validate_rejects_invalid_severity_levels
        create_sample_config(@temp_dir, "scanning" => { "severity_filter" => %w[INVALID CRITICAL] })

        error = assert_raises(ConfigError) do
          Config.new
        end

        assert_match(/Invalid severity levels: INVALID/, error.message)
      end

      def test_validate_rejects_timeout_below_minimum
        create_sample_config(@temp_dir, "scanning" => { "timeout" => 5 })

        error = assert_raises(ConfigError) do
          Config.new
        end

        assert_match(/Timeout must be at least 10 seconds/, error.message)
      end

      def test_validate_rejects_invalid_expiration_date
        ignores = [
          { "id" => "CVE-2023-12345", "reason" => "Test", "expires" => "invalid-date" }
        ]
        create_sample_config(@temp_dir, "ignores" => ignores)

        error = assert_raises(ConfigError) do
          Config.new
        end

        assert_match(/Invalid expiration date/, error.message)
      end

      def test_validate_requires_reason_for_ignores
        ignores = [
          { "id" => "CVE-2023-12345" }
        ]
        create_sample_config(@temp_dir, "ignores" => ignores)

        error = assert_raises(ConfigError) do
          Config.new
        end

        assert_match(/missing required 'reason' field/, error.message)
      end

      def test_validate_accepts_valid_configuration
        create_sample_config(@temp_dir, {
                               "enabled" => true,
                               "scanning" => {
                                 "timeout" => 120,
                                 "severity_filter" => %w[CRITICAL HIGH]
                               },
                               "ignores" => [
                                 { "id" => "CVE-2023-12345", "reason" => "Valid ignore", "expires" => "2025-12-31" }
                               ]
                             })

        # Should not raise
        config = Config.new
        assert config
      end

      def test_env_variables_override_config_file
        create_sample_config(@temp_dir, "enabled" => true)

        with_env("BUNDLER_TRIVY_SKIP", "true") do
          config = Config.new
          assert config.skip_scan?, "ENV variable should override config file"
        end
      end
    end
  end
end
