# frozen_string_literal: true

require "test_helper"

module Bundler
  module Trivy
    class ScannerTest < Minitest::Test
      def setup
        super
        @temp_dir = create_temp_dir
        create_sample_lockfile(@temp_dir)
        @config = Config.new
        @scanner = Scanner.new(@temp_dir, @config)
      end

      def teardown
        super
        FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
      end

      def test_initialize_with_project_root
        scanner = Scanner.new("/path/to/project")
        assert_equal "/path/to/project", scanner.project_root
      end

      def test_initialize_with_config
        config = Config.new
        scanner = Scanner.new("/path/to/project", config)
        assert_equal config, scanner.config
      end

      def test_initialize_creates_default_config
        scanner = Scanner.new("/path/to/project")
        assert_instance_of Config, scanner.config
      end

      def test_trivy_available_returns_true_when_installed
        # This test assumes Trivy is installed
        # Skip if Trivy is not available
        skip "Trivy not installed" unless system("which trivy > /dev/null 2>&1")

        assert @scanner.trivy_available?
      end

      def test_trivy_available_returns_false_when_not_installed
        # Mock the system call to return false
        @scanner.stub :system, false do
          refute @scanner.trivy_available?
        end
      end

      def test_scan_raises_error_on_trivy_failure
        # Mock Open3.capture3 to simulate Trivy failure
        mock_output = ["", "Database error", OpenStruct.new(exitstatus: 2)]

        Open3.stub :capture3, mock_output do
          error = assert_raises(ScanError) do
            @scanner.scan
          end

          assert_match(/Trivy scan failed with exit code 2/, error.message)
          assert_match(/Possible causes/, error.message)
          assert_match(/Troubleshooting steps/, error.message)
        end
      end

      def test_scan_raises_error_on_json_parse_failure
        # Mock Open3.capture3 to return invalid JSON
        mock_output = ["invalid json", "", OpenStruct.new(exitstatus: 0)]

        Open3.stub :capture3, mock_output do
          error = assert_raises(ScanError) do
            @scanner.scan
          end

          assert_match(/Invalid JSON output from Trivy/, error.message)
          assert_match(/Trivy version incompatibility/, error.message)
        end
      end

      def test_scan_raises_error_on_timeout
        # Mock Open3.capture3 to raise Timeout::Error
        Open3.stub :capture3, ->(*_args, **_kwargs) { raise Timeout::Error } do
          error = assert_raises(ScanError) do
            @scanner.scan
          end

          assert_match(/Trivy scan timed out after/, error.message)
          assert_match(/Increase timeout in config/, error.message)
        end
      end

      def test_scan_returns_scan_result_on_success
        # Mock successful Trivy output with no vulnerabilities
        mock_json = { "Results" => [] }.to_json
        mock_output = [mock_json, "", OpenStruct.new(exitstatus: 0)]

        Open3.stub :capture3, mock_output do
          result = @scanner.scan
          assert_instance_of ScanResult, result
          assert_equal 0, result.vulnerability_count
        end
      end

      def test_scan_handles_exit_code_1_with_vulnerabilities
        # Exit code 1 means vulnerabilities found (success case)
        mock_json = mock_trivy_output([sample_vulnerability])
        mock_output = [mock_json, "", OpenStruct.new(exitstatus: 1)]

        Open3.stub :capture3, mock_output do
          result = @scanner.scan
          assert_instance_of ScanResult, result
          assert result.vulnerability_count.positive?
        end
      end

      def test_scan_uses_configured_timeout
        config = Config.new
        with_env("BUNDLER_TRIVY_TIMEOUT", "300") do
          config = Config.new
          scanner = Scanner.new(@temp_dir, config)

          # Verify timeout is passed to Open3.capture3
          Open3.stub :capture3, lambda { |*_args, **kwargs|
            assert_equal 300, kwargs[:timeout]
            [mock_trivy_output([]), "", OpenStruct.new(exitstatus: 0)]
          } do
            scanner.scan
          end
        end
      end

      def test_scan_applies_severity_filter
        create_sample_config(@temp_dir, "scanning" => { "severity_filter" => %w[CRITICAL HIGH] })
        ENV["BUNDLE_GEMFILE"] = File.join(@temp_dir, "Gemfile")

        config = Config.new
        scanner = Scanner.new(@temp_dir, config)

        # Verify severity filter is included in command args
        Open3.stub :capture3, lambda { |*args, **_kwargs|
          assert_includes args, "--severity"
          assert_includes args, "CRITICAL,HIGH"
          [mock_trivy_output([]), "", OpenStruct.new(exitstatus: 0)]
        } do
          scanner.scan
        end
      ensure
        ENV.delete("BUNDLE_GEMFILE")
      end

      def test_build_error_message_includes_troubleshooting
        scanner = Scanner.new(@temp_dir)
        message = scanner.send(:build_error_message, 2, "some error")

        assert_match(/exit code 2/, message)
        assert_match(/some error/, message)
        assert_match(/Possible causes/, message)
        assert_match(/Troubleshooting steps/, message)
        assert_match(/trivy image --download-db-only/, message)
      end

      def test_build_json_error_message_includes_version_info
        scanner = Scanner.new(@temp_dir)
        error = JSON::ParserError.new("unexpected token")
        message = scanner.send(:build_json_error_message, error, "bad output")

        assert_match(/Invalid JSON output/, message)
        assert_match(/unexpected token/, message)
        assert_match(/Trivy version incompatibility/, message)
        assert_match(/bad output/, message)
      end

      def test_build_timeout_error_message_includes_suggestions
        scanner = Scanner.new(@temp_dir)
        message = scanner.send(:build_timeout_error_message, 120)

        assert_match(/timed out after 120 seconds/, message)
        assert_match(/Increase timeout/, message)
        assert_match(/scanning.timeout: 240/, message)
        assert_match(/300\+ seconds/, message)
      end

      def test_build_trivy_args_includes_basic_options
        scanner = Scanner.new(@temp_dir)
        args = scanner.send(:build_trivy_args)

        assert_includes args, "trivy"
        assert_includes args, "fs"
        assert_includes args, "--scanners"
        assert_includes args, "vuln"
        assert_includes args, "--format"
        assert_includes args, "json"
        assert_includes args, "--quiet"
        assert_includes args, @temp_dir
      end

      def test_parse_json_returns_hash_for_valid_json
        scanner = Scanner.new(@temp_dir)
        result = scanner.send(:parse_json, '{"key": "value"}')

        assert_equal({ "key" => "value" }, result)
      end

      def test_parse_json_returns_empty_hash_for_empty_string
        scanner = Scanner.new(@temp_dir)
        result = scanner.send(:parse_json, "")

        assert_equal({}, result)
      end
    end
  end
end
