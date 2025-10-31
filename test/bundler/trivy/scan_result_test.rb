# frozen_string_literal: true

require "test_helper"

module Bundler
  module Trivy
    class ScanResultTest < Minitest::Test
      def setup
        super
        @temp_dir = create_temp_dir
        @config = Config.new
      end

      def teardown
        super
        FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
      end

      def test_initialize_with_empty_data
        result = ScanResult.new({}, @config)
        assert_equal({}, result.data)
      end

      def test_initialize_with_nil_data
        result = ScanResult.new(nil, @config)
        assert_equal({}, result.data)
      end

      def test_vulnerabilities_returns_empty_array_for_no_results
        data = {"Results" => []}
        result = ScanResult.new(data, @config)

        assert_equal [], result.vulnerabilities
      end

      def test_vulnerabilities_extracts_from_trivy_data
        data = JSON.parse(mock_trivy_output([sample_vulnerability(cve_id: "CVE-2023-99999")]))
        result = ScanResult.new(data, @config)

        assert_equal 1, result.vulnerabilities.count
        assert_instance_of Vulnerability, result.vulnerabilities.first
      end

      def test_vulnerabilities_filters_ignored_cves
        vuln1 = sample_vulnerability(cve_id: "CVE-2023-11111")
        vuln2 = sample_vulnerability(cve_id: "CVE-2023-22222")

        data = JSON.parse(mock_trivy_output([vuln1, vuln2]))

        # Configure to ignore CVE-2023-11111
        ignores = [{"id" => "CVE-2023-11111", "reason" => "Test ignore"}]
        create_sample_config(@temp_dir, "ignores" => ignores)

        ENV["BUNDLE_GEMFILE"] = File.join(@temp_dir, "Gemfile")
        config = Config.new
        result = ScanResult.new(data, config)

        assert_equal 1, result.vulnerabilities.count
        assert_equal "CVE-2023-22222", result.vulnerabilities.first.id
      ensure
        ENV.delete("BUNDLE_GEMFILE")
      end

      def test_by_severity_groups_vulnerabilities
        critical = sample_vulnerability(severity: "CRITICAL", cve_id: "CVE-2023-99998")
        high = sample_vulnerability(severity: "HIGH", cve_id: "CVE-2023-99999")

        data = JSON.parse(mock_trivy_output([critical, high]))
        result = ScanResult.new(data, @config)

        grouped = result.by_severity

        assert_equal 1, grouped["CRITICAL"].count
        assert_equal 1, grouped["HIGH"].count
      end

      def test_critical_vulnerabilities_filters_correctly
        critical = sample_vulnerability(severity: "CRITICAL", cve_id: "CVE-2023-99997")
        high = sample_vulnerability(severity: "HIGH", cve_id: "CVE-2023-99999")

        data = JSON.parse(mock_trivy_output([critical, high]))
        result = ScanResult.new(data, @config)

        criticals = result.critical_vulnerabilities

        assert_equal 1, criticals.count
        assert criticals.first.critical?
      end

      def test_high_vulnerabilities_filters_correctly
        critical = sample_vulnerability(severity: "CRITICAL", cve_id: "CVE-2023-99996")
        high = sample_vulnerability(severity: "HIGH", cve_id: "CVE-2023-99999")

        data = JSON.parse(mock_trivy_output([critical, high]))
        result = ScanResult.new(data, @config)

        highs = result.high_vulnerabilities

        assert_equal 1, highs.count
        assert highs.first.high?
      end

      def test_has_vulnerabilities_returns_true_when_present
        data = JSON.parse(mock_trivy_output([sample_vulnerability(cve_id: "CVE-2023-99995")]))
        result = ScanResult.new(data, @config)

        assert result.has_vulnerabilities?
      end

      def test_has_vulnerabilities_returns_false_when_none
        data = {"Results" => []}
        result = ScanResult.new(data, @config)

        refute result.has_vulnerabilities?
      end

      def test_has_critical_vulnerabilities_returns_true_when_present
        critical = sample_vulnerability(severity: "CRITICAL", cve_id: "CVE-2023-99994")
        data = JSON.parse(mock_trivy_output([critical]))
        result = ScanResult.new(data, @config)

        assert result.has_critical_vulnerabilities?
      end

      def test_has_critical_vulnerabilities_returns_false_when_none
        high = sample_vulnerability(severity: "HIGH", cve_id: "CVE-2023-99993")
        data = JSON.parse(mock_trivy_output([high]))
        result = ScanResult.new(data, @config)

        refute result.has_critical_vulnerabilities?
      end

      def test_vulnerability_count_returns_correct_number
        vulns = [
          sample_vulnerability(cve_id: "CVE-2023-11111"),
          sample_vulnerability(cve_id: "CVE-2023-22222"),
          sample_vulnerability(cve_id: "CVE-2023-33333")
        ]
        data = JSON.parse(mock_trivy_output(vulns))
        result = ScanResult.new(data, @config)

        assert_equal 3, result.vulnerability_count
      end

      def test_severity_counts_returns_breakdown
        vulns = [
          sample_vulnerability(severity: "CRITICAL", cve_id: "CVE-2023-11111"),
          sample_vulnerability(severity: "CRITICAL", cve_id: "CVE-2023-22222"),
          sample_vulnerability(severity: "HIGH", cve_id: "CVE-2023-33333")
        ]
        data = JSON.parse(mock_trivy_output(vulns))
        result = ScanResult.new(data, @config)

        counts = result.severity_counts

        assert_equal 2, counts["CRITICAL"]
        assert_equal 1, counts["HIGH"]
      end

      def test_handles_nil_vulnerabilities_in_results
        data = {
          "Results" => [
            {"Target" => "Gemfile.lock", "Vulnerabilities" => nil}
          ]
        }
        result = ScanResult.new(data, @config)

        assert_equal [], result.vulnerabilities
      end

      def test_handles_empty_vulnerabilities_in_results
        data = {
          "Results" => [
            {"Target" => "Gemfile.lock", "Vulnerabilities" => []}
          ]
        }
        result = ScanResult.new(data, @config)

        assert_equal [], result.vulnerabilities
      end

      def test_handles_multiple_targets
        data = {
          "Results" => [
            {
              "Target" => "Gemfile.lock",
              "Vulnerabilities" => [sample_vulnerability(cve_id: "CVE-2023-11111")]
            },
            {
              "Target" => "vendor/bundle",
              "Vulnerabilities" => [sample_vulnerability(cve_id: "CVE-2023-22222")]
            }
          ]
        }
        result = ScanResult.new(data, @config)

        assert_equal 2, result.vulnerabilities.count
        assert_equal ["CVE-2023-11111", "CVE-2023-22222"], result.vulnerabilities.map(&:id)
      end
    end
  end
end
