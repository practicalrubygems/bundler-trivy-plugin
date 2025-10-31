# frozen_string_literal: true

require "test_helper"
require "stringio"

module Bundler
  module Trivy
    class ReporterTest < Minitest::Test
      def setup
        super
        @config = Config.new
        @empty_results = ScanResult.new({}, @config)
        @results_with_vulns = ScanResult.new(JSON.parse(mock_trivy_output([sample_vulnerability(cve_id: "CVE-2023-99999")])), @config)
      end

      def test_initialize_with_scan_result_and_config
        reporter = Reporter.new(@empty_results, @config)
        assert_equal @empty_results, reporter.instance_variable_get(:@result)
        assert_equal @config, reporter.instance_variable_get(:@config)
      end

      def test_initialize_creates_default_config
        reporter = Reporter.new(@empty_results)
        assert_instance_of Config, reporter.instance_variable_get(:@config)
      end

      def test_display_calls_display_json_when_config_json_output
        config_mock = Minitest::Mock.new
        config_mock.expect :json_output?, true

        reporter = Reporter.new(@empty_results, config_mock)
        reporter.stub :display_json, nil do
          reporter.display
        end

        config_mock.verify
      end

      def test_display_calls_display_clean_result_when_no_vulnerabilities
        config_mock = Minitest::Mock.new
        config_mock.expect :json_output?, false

        reporter = Reporter.new(@empty_results, config_mock)
        reporter.stub :display_clean_result, nil do
          reporter.display
        end

        config_mock.verify
      end

      def test_display_calls_full_report_when_vulnerabilities_present
        config_mock = Minitest::Mock.new
        config_mock.expect :json_output?, false

        reporter = Reporter.new(@results_with_vulns, config_mock)
        reporter.stub :display_summary, nil do
          reporter.stub :display_vulnerabilities_by_severity, nil do
            reporter.stub :display_remediation_advice, nil do
              reporter.display
            end
          end
        end

        config_mock.verify
      end

      def test_display_clean_result_outputs_success_message
        output = capture_stdout do
          reporter = Reporter.new(@empty_results)
          reporter.send(:display_clean_result)
        end

        assert_match "No vulnerabilities found by Trivy", output
      end

      def test_display_summary_outputs_vulnerability_counts
        output = capture_stdout do
          reporter = Reporter.new(@results_with_vulns)
          reporter.send(:display_summary)
        end

        assert_match "CRITICAL: 1", output
      end

      def test_display_vulnerabilities_by_severity_outputs_vulnerability_details
        output = capture_stdout do
          reporter = Reporter.new(@results_with_vulns)
          reporter.send(:display_vulnerabilities_by_severity)
        end

        assert_match "CRITICAL Vulnerabilities:", output
        assert_match "rack (2.2.3)", output
        assert_match "CVE-2023-99999", output
        assert_match "Fixed in:", output
      end

      def test_display_vulnerability_outputs_fixable_vulnerability
        vuln = Vulnerability.new(sample_vulnerability, "Gemfile.lock")

        output = capture_stdout do
          reporter = Reporter.new(@results_with_vulns)
          reporter.send(:display_vulnerability, vuln)
        end

        assert_match "rack (2.2.3)", output
        assert_match "CVE-2023-12345", output
        assert_match "Fixed in:", output
        assert_match "https://avd.aquasec.com/nvd/cve-2023-12345", output
      end

      def test_display_vulnerability_outputs_unfixable_vulnerability
        vuln_data = sample_vulnerability
        vuln_data["FixedVersion"] = nil
        vuln = Vulnerability.new(vuln_data, "Gemfile.lock")

        output = capture_stdout do
          reporter = Reporter.new(@results_with_vulns)
          reporter.send(:display_vulnerability, vuln)
        end

        assert_match "No fix available yet", output
      end

      def test_display_remediation_advice_outputs_update_commands
        output = capture_stdout do
          reporter = Reporter.new(@results_with_vulns)
          reporter.send(:display_remediation_advice)
        end

        assert_match "Recommended Actions:", output
        assert_match "Update rack to 2.3.0: bundle update rack", output
      end

      def test_display_remediation_advice_skips_when_no_fixable_vulns
        # Create results with unfixable vulnerability
        vuln_data = sample_vulnerability
        vuln_data["FixedVersion"] = nil
        results = ScanResult.new(JSON.parse(mock_trivy_output([vuln_data])), @config)

        output = capture_stdout do
          reporter = Reporter.new(results)
          reporter.send(:display_remediation_advice)
        end

        assert_empty output
      end

      def test_display_json_outputs_machine_readable_format
        output = capture_stdout do
          reporter = Reporter.new(@results_with_vulns)
          reporter.send(:display_json)
        end

        json = JSON.parse(output)
        assert_equal 1, json["vulnerabilities"].length
        assert_equal "CVE-2023-99999", json["vulnerabilities"].first["id"]
        assert_equal 1, json["summary"]["total"]
        assert_equal 1, json["summary"]["by_severity"]["CRITICAL"]
      end

      def test_color_for_severity_returns_correct_colors
        reporter = Reporter.new(@empty_results)

        assert_equal :red, reporter.send(:color_for_severity, "CRITICAL")
        assert_equal :red, reporter.send(:color_for_severity, "HIGH")
        assert_equal :yellow, reporter.send(:color_for_severity, "MEDIUM")
        assert_equal :blue, reporter.send(:color_for_severity, "LOW")
        assert_equal :default, reporter.send(:color_for_severity, "UNKNOWN")
      end

      def test_severity_order_returns_correct_ordering
        reporter = Reporter.new(@empty_results)

        assert_equal 0, reporter.send(:severity_order, "CRITICAL")
        assert_equal 1, reporter.send(:severity_order, "HIGH")
        assert_equal 2, reporter.send(:severity_order, "MEDIUM")
        assert_equal 3, reporter.send(:severity_order, "LOW")
        assert_equal 4, reporter.send(:severity_order, "UNKNOWN")
        assert_equal 99, reporter.send(:severity_order, "INVALID")
      end

      def test_colorize_applies_ansi_codes_when_enabled
        reporter = Reporter.new(@empty_results)

        # Mock color enabled
        reporter.stub :color_enabled?, true do
          assert_equal "\e[31mtest\e[0m", reporter.send(:colorize, "test", 31)
        end
      end

      def test_colorize_returns_plain_text_when_disabled
        reporter = Reporter.new(@empty_results)

        reporter.stub :color_enabled?, false do
          assert_equal "test", reporter.send(:colorize, "test", 31)
        end
      end

      def test_color_enabled_returns_false_when_no_color_env_set
        with_env("NO_COLOR", "1") do
          reporter = Reporter.new(@empty_results)
          refute reporter.send(:color_enabled?)
        end
      end

      def test_color_enabled_returns_false_when_not_tty
        original_stdout = $stdout
        $stdout = StringIO.new

        reporter = Reporter.new(@empty_results)
        refute reporter.send(:color_enabled?)
      ensure
        $stdout = original_stdout
      end

      def test_color_enabled_returns_true_when_tty_and_no_no_color
        # Mock $stdout.tty? to return true
        original_tty = $stdout.method(:tty?)
        $stdout.define_singleton_method(:tty?) { true }

        reporter = Reporter.new(@empty_results)
        assert reporter.send(:color_enabled?)
      ensure
        # Restore original method
        $stdout.define_singleton_method(:tty?, original_tty)
      end

      private

      def capture_stdout
        original_stdout = $stdout
        $stdout = StringIO.new
        yield
        $stdout.string
      ensure
        $stdout = original_stdout
      end
    end
  end
end
