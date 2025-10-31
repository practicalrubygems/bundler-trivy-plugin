# frozen_string_literal: true

require "bundler"
require_relative "scanner"
require_relative "reporter"
require_relative "config"

module Bundler
  module Trivy
    # Main plugin class that integrates Trivy security scanning into Bundler's workflow.
    #
    # This plugin hooks into Bundler's after-install-all event to automatically scan
    # Ruby dependencies for known security vulnerabilities using Aqua Security's Trivy scanner.
    #
    # @example Running a scan after bundle install
    #   # Automatically triggered after: bundle install
    #   Bundler::Trivy::Plugin.scan_after_install
    class Plugin
      # Executes a Trivy security scan after bundle install completes.
      #
      # This method is called automatically by Bundler's plugin system after all gems
      # have been installed. It performs the following steps:
      # 1. Loads configuration from file and environment variables
      # 2. Checks if scanning is enabled and Trivy is available
      # 3. Runs Trivy scan on the Gemfile.lock
      # 4. Displays results to the user via the Reporter
      # 5. Exits with non-zero status if critical vulnerabilities found (based on config)
      #
      # @return [void]
      #
      # @example Manually triggering a scan
      #   Bundler::Trivy::Plugin.scan_after_install
      def self.scan_after_install
        config = Config.new

        # Skip if explicitly disabled via config or environment variable
        return if config.skip_scan?

        # Verify Gemfile.lock exists before attempting to scan
        unless File.exist?(Bundler.default_lockfile)
          Bundler.ui.warn "Gemfile.lock not found, skipping scan"
          return
        end

        lockfile_path = Bundler.default_lockfile.to_s
        project_root = File.dirname(lockfile_path)

        scanner = Scanner.new(project_root, config)

        # Check if Trivy binary is available in PATH
        unless scanner.trivy_available?
          Bundler.ui.warn "Trivy not found, skipping scan"
          Bundler.ui.info "Install: https://trivy.dev/docs/getting-started/installation/"
          return
        end

        begin
          # Execute the security scan
          results = scanner.scan

          # Display formatted results to the user
          reporter = Reporter.new(results, config)
          reporter.display

          # Exit with error code if vulnerabilities exceed configured thresholds
          handle_exit_code(results, config)
        rescue StandardError => e
          Bundler.ui.warn "Trivy scan failed: #{e.message}"
          Bundler.ui.debug e.backtrace.join("\n") if ENV["DEBUG"]
        end
      end

      # Handles exit code based on vulnerability severity and configuration.
      #
      # This method determines whether to exit with a non-zero status based on
      # the scan results and configured failure thresholds. This is particularly
      # useful in CI/CD pipelines where builds should fail on security issues.
      #
      # @param results [ScanResult] The scan results containing vulnerability information
      # @param config [Config] Configuration object with fail_on settings
      # @return [void]
      #
      # @example Failing on critical vulnerabilities
      #   config = Config.new
      #   # With config.fail_on_critical? == true and critical vulns found
      #   handle_exit_code(results, config)
      #   # => exits with status 1
      def self.handle_exit_code(results, config)
        if results.has_critical_vulnerabilities? && config.fail_on_critical?
          Bundler.ui.error "CRITICAL vulnerabilities found. Install blocked."
          exit 1
        elsif results.has_vulnerabilities? && config.fail_on_any?
          Bundler.ui.error "Vulnerabilities found. Install blocked."
          exit 1
        end
      end
    end
  end
end
