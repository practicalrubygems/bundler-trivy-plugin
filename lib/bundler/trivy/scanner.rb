# frozen_string_literal: true

require "json"
require "open3"
require "timeout"
require_relative "scan_result"

module Bundler
  module Trivy
    # Executes Trivy security scans on Ruby projects.
    #
    # The Scanner class is responsible for invoking the Trivy command-line tool,
    # parsing its JSON output, and returning structured results. It handles
    # timeout management, error conditions, and severity filtering.
    #
    # @example Basic usage
    #   config = Config.new
    #   scanner = Scanner.new("/path/to/project", config)
    #   if scanner.trivy_available?
    #     results = scanner.scan
    #     puts "Found #{results.vulnerability_count} vulnerabilities"
    #   end
    class Scanner
      # @return [String] the root directory of the project being scanned
      attr_reader :project_root

      # @return [Config] the configuration object for the scanner
      attr_reader :config

      # Initializes a new Scanner instance.
      #
      # @param project_root [String] The root directory of the project to scan
      # @param config [Config, nil] Configuration object. If nil, creates a new Config with defaults
      #
      # @example Create scanner with default config
      #   scanner = Scanner.new("/path/to/project")
      #
      # @example Create scanner with custom config
      #   config = Config.new
      #   scanner = Scanner.new("/path/to/project", config)
      def initialize(project_root, config = nil)
        @project_root = project_root
        @config = config || Config.new
      end

      # Executes a Trivy security scan on the project.
      #
      # This method runs the Trivy CLI tool with appropriate arguments, captures
      # its JSON output, and parses it into a ScanResult object. The scan checks
      # for known vulnerabilities in Ruby dependencies listed in Gemfile.lock.
      #
      # @return [ScanResult] Parsed scan results containing vulnerability information
      #
      # @raise [ScanError] If Trivy execution fails with exit code > 1
      # @raise [ScanError] If Trivy output is not valid JSON
      # @raise [ScanError] If the scan exceeds the configured timeout
      #
      # @example Scanning a project
      #   scanner = Scanner.new("/path/to/project")
      #   begin
      #     results = scanner.scan
      #     puts "Scan completed: #{results.vulnerability_count} issues found"
      #   rescue ScanError => e
      #     puts "Scan failed: #{e.message}"
      #   end
      def scan
        args = build_trivy_args
        timeout = @config.trivy_timeout

        # Execute Trivy with timeout for robust command execution
        stdout, stderr, status = Timeout.timeout(timeout) do
          Open3.capture3(*args)
        end

        # Handle Trivy exit codes:
        # 0 = success, no vulnerabilities
        # 1 = success, vulnerabilities found
        # >1 = error condition
        raise ScanError, build_error_message(status.exitstatus, stderr) if status.exitstatus > 1

        # Parse JSON output into structured data
        data = parse_json(stdout)
        ScanResult.new(data, @config)
      rescue JSON::ParserError => e
        raise ScanError, build_json_error_message(e, stdout)
      rescue Timeout::Error
        raise ScanError, build_timeout_error_message(timeout)
      end

      # Checks if the Trivy binary is available in the system PATH.
      #
      # This method performs a defensive check to verify that Trivy is installed
      # and accessible before attempting to run a scan. It prevents cryptic errors
      # by failing early with a clear message.
      #
      # @return [Boolean] true if Trivy is available, false otherwise
      #
      # @example Check availability before scanning
      #   scanner = Scanner.new("/path/to/project")
      #   if scanner.trivy_available?
      #     results = scanner.scan
      #   else
      #     puts "Please install Trivy first"
      #   end
      def trivy_available?
        system("which trivy > /dev/null 2>&1")
      end

      private

      # Builds the command-line arguments for the Trivy invocation.
      #
      # @return [Array<String>] Array of command arguments
      def build_trivy_args
        args = [
          "trivy", "fs",
          "--scanners", "vuln",
          "--format", "json",
          "--quiet"
        ]

        # Add severity filtering if configured
        severity_filter = @config.severity_filter
        args += ["--severity", severity_filter.join(",")] if severity_filter&.any?

        args << @project_root
        args
      end

      # Parses Trivy JSON output into a Ruby hash.
      #
      # @param json_string [String] JSON string from Trivy
      # @return [Hash] Parsed JSON data
      def parse_json(json_string)
        return {} if json_string.empty?

        JSON.parse(json_string)
      end

      # Builds a detailed error message for Trivy execution failures.
      #
      # @param exit_code [Integer] The exit code from Trivy
      # @param stderr [String] Standard error output from Trivy
      # @return [String] Formatted error message with troubleshooting guidance
      def build_error_message(exit_code, stderr)
        <<~ERROR
          Trivy scan failed with exit code #{exit_code}

          Error output:
          #{stderr}

          Possible causes:
          - Trivy database is outdated or corrupted
          - Network connectivity issues during database update
          - Invalid or corrupted Gemfile.lock
          - Insufficient disk space

          Troubleshooting steps:
          1. Update Trivy database: trivy image --download-db-only
          2. Check network connectivity
          3. Verify Gemfile.lock is valid: bundle check
          4. Check disk space: df -h

          For more information, visit: https://trivy.dev/docs/
        ERROR
      end

      # Builds an error message for JSON parsing failures.
      #
      # @param error [JSON::ParserError] The JSON parsing error
      # @param output [String] The output that failed to parse
      # @return [String] Formatted error message
      def build_json_error_message(error, output)
        <<~ERROR
          Invalid JSON output from Trivy: #{error.message}

          This may indicate:
          - Trivy version incompatibility (requires Trivy v0.40.0 or later)
          - Corrupted output due to interrupted execution
          - System error messages mixed with JSON output

          Output received:
          #{output.slice(0, 500)}#{"...\n[truncated]" if output.length > 500}

          Troubleshooting:
          1. Check Trivy version: trivy --version
          2. Update Trivy to latest version
          3. Run Trivy manually: trivy fs --format json #{@project_root}
        ERROR
      end

      # Builds an error message for timeout conditions.
      #
      # @param timeout [Integer] The timeout value that was exceeded
      # @return [String] Formatted error message
      def build_timeout_error_message(timeout)
        <<~ERROR
          Trivy scan timed out after #{timeout} seconds

          This may occur when:
          - Scanning a very large project with many dependencies
          - Slow network connection during database updates
          - System resource constraints

          Solutions:
          1. Increase timeout in config: scanning.timeout: #{timeout * 2}
          2. Update Trivy database before scanning: trivy image --download-db-only
          3. Check system resources: top or htop

          Current timeout: #{timeout} seconds
          Suggested timeout for large projects: 300+ seconds
        ERROR
      end
    end

    # Exception raised when a Trivy scan fails.
    #
    # This error is raised for various scan failures including:
    # - Trivy execution errors (exit code > 1)
    # - Invalid JSON output
    # - Timeout conditions
    # - Database update failures
    class ScanError < StandardError; end
  end
end
