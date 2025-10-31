# frozen_string_literal: true

require "yaml"
require "date"

module Bundler
  module Trivy
    # Configuration management for the Bundler Trivy plugin.
    #
    # Config handles loading and merging configuration from multiple sources:
    # - YAML configuration files (.bundler-trivy.yml)
    # - Environment variables (BUNDLER_TRIVY_*)
    # - Global configuration (~/.bundle/trivy.yml)
    # - CI environment detection and smart defaults
    #
    # Environment variables always take precedence over file configuration,
    # allowing for easy overrides in CI/CD environments.
    #
    # @example Basic usage
    #   config = Config.new
    #   config.skip_scan? # => false
    #   config.fail_on_critical? # => true (in CI), false (locally)
    #
    # @example With environment variable override
    #   ENV["BUNDLER_TRIVY_FAIL_ON_CRITICAL"] = "true"
    #   config = Config.new
    #   config.fail_on_critical? # => true
    class Config
      # Initializes a new Config instance.
      #
      # Loads configuration from file and validates it. Configuration is loaded
      # from multiple sources and merged with the following precedence:
      # 1. Environment variables (highest priority)
      # 2. Project config file (.bundler-trivy.yml)
      # 3. Global config file (~/.bundle/trivy.yml)
      # 4. Built-in defaults (lowest priority)
      #
      # @raise [ConfigError] If configuration validation fails
      #
      # @example Create with default settings
      #   config = Config.new
      def initialize
        @file_config = load_config_file
        validate! if @file_config.any?
      end

      # Determines if scanning should be skipped entirely.
      #
      # @return [Boolean] true if scanning is disabled, false otherwise
      #
      # @example Check if scanning is enabled
      #   config.skip_scan? # => false
      #
      # @example Disable via environment variable
      #   ENV["BUNDLER_TRIVY_SKIP"] = "true"
      #   config.skip_scan? # => true
      def skip_scan?
        env_bool("BUNDLER_TRIVY_SKIP", file_value("enabled", true) == false)
      end

      # Determines if the plugin should exit with error on CRITICAL vulnerabilities.
      #
      # Defaults to true in CI environments, false in local development.
      # This allows strict enforcement in CI while keeping local development flexible.
      #
      # @return [Boolean] true if should fail on critical vulnerabilities
      #
      # @example In CI environment
      #   ENV["CI"] = "true"
      #   config.fail_on_critical? # => true
      #
      # @example Force enable locally
      #   ENV["BUNDLER_TRIVY_FAIL_ON_CRITICAL"] = "true"
      #   config.fail_on_critical? # => true
      def fail_on_critical?
        env_bool("BUNDLER_TRIVY_FAIL_ON_CRITICAL",
          file_value(%w[fail_on critical], ci_environment?))
      end

      # Determines if the plugin should exit with error on HIGH severity vulnerabilities.
      #
      # @return [Boolean] true if should fail on high severity vulnerabilities
      #
      # @example Enable strict mode
      #   ENV["BUNDLER_TRIVY_FAIL_ON_HIGH"] = "true"
      #   config.fail_on_high? # => true
      def fail_on_high?
        env_bool("BUNDLER_TRIVY_FAIL_ON_HIGH",
          file_value(%w[fail_on high], false))
      end

      # Determines if the plugin should exit with error on ANY vulnerabilities.
      #
      # This is the most strict setting, causing failure on vulnerabilities
      # of any severity level (including LOW and MEDIUM).
      #
      # @return [Boolean] true if should fail on any vulnerabilities
      #
      # @example Ultra-strict mode
      #   ENV["BUNDLER_TRIVY_FAIL_ON_ANY"] = "true"
      #   config.fail_on_any? # => true
      def fail_on_any?
        env_bool("BUNDLER_TRIVY_FAIL_ON_ANY", false)
      end

      # Determines if output should be in compact format.
      #
      # Compact format is more suitable for CI logs with less visual formatting.
      # Defaults to true in CI environments, false in local development.
      #
      # @return [Boolean] true if compact output is enabled
      def compact_output?
        env_bool("BUNDLER_TRIVY_COMPACT",
          file_value(%w[output compact], ci_environment?))
      end

      # Determines if output should be in JSON format.
      #
      # JSON output is useful for machine parsing and integration with other tools.
      #
      # @return [Boolean] true if JSON output is enabled
      #
      # @example Enable JSON output
      #   ENV["BUNDLER_TRIVY_FORMAT"] = "json"
      #   config.json_output? # => true
      def json_output?
        format = ENV["BUNDLER_TRIVY_FORMAT"] || file_value(%w[output format], "terminal")
        format == "json"
      end

      # Returns the minimum severity threshold for reporting.
      #
      # @return [String] Severity threshold (CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN)
      def severity_threshold
        ENV["BUNDLER_TRIVY_SEVERITY"] || "CRITICAL"
      end

      # Returns the list of severity levels to filter for during scanning.
      #
      # @return [Array<String>] Array of severity levels (e.g., ["CRITICAL", "HIGH"])
      #
      # @example Get configured severities
      #   config.severity_filter # => ["CRITICAL", "HIGH"]
      def severity_filter
        filter = file_value(%w[scanning severity_filter], [])
        return filter if filter.is_a?(Array)

        []
      end

      # Returns the configured timeout for Trivy scans in seconds.
      #
      # @return [Integer] Timeout in seconds (minimum 10, default 120)
      #
      # @example Get default timeout
      #   config.trivy_timeout # => 120
      #
      # @example Override via environment
      #   ENV["BUNDLER_TRIVY_TIMEOUT"] = "300"
      #   config.trivy_timeout # => 300
      def trivy_timeout
        ENV.fetch("BUNDLER_TRIVY_TIMEOUT",
          file_value(%w[scanning timeout], 120)).to_i
      end

      # Returns the list of ignored CVEs from configuration.
      #
      # Each ignore entry should include an id, reason, and optionally an expires date.
      #
      # @return [Array<Hash>] Array of ignore entries
      #
      # @example Get ignored CVEs
      #   config.ignored_cves
      #   # => [{"id" => "CVE-2023-12345", "reason" => "False positive", "expires" => "2025-12-31"}]
      def ignored_cves
        file_value("ignores", [])
      end

      # Checks if a specific CVE is currently ignored.
      #
      # A CVE is considered ignored if it appears in the ignores list
      # and either has no expiration date or the expiration date is in the future.
      #
      # @param cve_id [String] The CVE identifier (e.g., "CVE-2023-12345")
      # @return [Boolean] true if the CVE should be ignored
      #
      # @example Check if CVE is ignored
      #   config.cve_ignored?("CVE-2023-12345") # => true/false
      def cve_ignored?(cve_id)
        ignored_cves.any? do |ignore_entry|
          ignore_entry["id"] == cve_id && !expired?(ignore_entry)
        end
      end

      # Detects if running in a CI/CD environment.
      #
      # Checks for common CI environment variables from popular CI platforms:
      # - Generic CI
      # - Travis CI
      # - GitLab CI
      # - GitHub Actions
      # - Jenkins
      #
      # @return [Boolean] true if running in CI environment
      #
      # @example Check CI status
      #   config.ci_environment? # => false (locally), true (in CI)
      def ci_environment?
        ENV["CI"] == "true" ||
          ENV["TRAVIS"] == "true" ||
          ENV["GITLAB_CI"] == "true" ||
          ENV["GITHUB_ACTIONS"] == "true" ||
          !ENV["JENKINS_URL"].nil?
      end

      # Validates the configuration for correctness.
      #
      # Checks for:
      # - Valid severity levels
      # - Minimum timeout values
      # - Valid expiration date formats
      # - Required fields in ignore entries
      #
      # @raise [ConfigError] If validation fails
      # @return [void]
      def validate!
        errors = []

        # Validate severity filter
        valid_severities = %w[CRITICAL HIGH MEDIUM LOW UNKNOWN]
        invalid = severity_filter - valid_severities
        errors << "Invalid severity levels: #{invalid.join(", ")}" unless invalid.empty?

        # Validate timeout
        errors << "Timeout must be at least 10 seconds" if trivy_timeout < 10

        # Validate ignore expiration dates and required fields
        ignored_cves.each do |ignore|
          if ignore["expires"]
            begin
              # Handle both string and Date objects
              ignore["expires"].is_a?(Date) ? ignore["expires"] : Date.parse(ignore["expires"].to_s)
            rescue ArgumentError
              errors << "Invalid expiration date for #{ignore["id"]}: #{ignore["expires"]}"
            end
          end

          errors << "Ignore entry for #{ignore["id"]} missing required 'reason' field" unless ignore["reason"]
        end

        return if errors.empty?

        raise ConfigError, "Configuration errors:\n  #{errors.join("\n  ")}"
      end

      private

      def env_bool(key, default)
        value = ENV.fetch(key, nil)
        return default if value.nil?

        %w[true 1].include?(value)
      end

      def file_value(key_path, default)
        keys = key_path.is_a?(Array) ? key_path : [key_path]
        value = keys.reduce(@file_config) do |config, key|
          config.is_a?(Hash) ? config[key] : nil
        end
        value.nil? ? default : value
      end

      def load_config_file
        config_path = config_file_path

        return {} unless File.exist?(config_path)

        config = YAML.safe_load_file(config_path, permitted_classes: [Date]) || {}

        # Load global config and merge
        global_config_path = File.expand_path("~/.bundle/trivy.yml")
        if File.exist?(global_config_path)
          global = YAML.safe_load_file(global_config_path, permitted_classes: [Date]) || {}
          config = deep_merge(global, config)
        end

        config
      rescue => e
        Bundler.ui.warn "Failed to load config (#{config_path}): #{e.message}"
        {}
      end

      def config_file_path
        env = ENV.fetch("BUNDLER_TRIVY_ENV", nil)

        if env && !env.empty?
          env_config = File.join(project_root, ".bundler-trivy.#{env}.yml")
          return env_config if File.exist?(env_config)
        end

        File.join(project_root, ".bundler-trivy.yml")
      end

      def project_root
        Bundler.default_gemfile.dirname.to_s
      end

      def deep_merge(hash1, hash2)
        hash1.merge(hash2) do |_, v1, v2|
          (v1.is_a?(Hash) && v2.is_a?(Hash)) ? deep_merge(v1, v2) : v2
        end
      end

      def expired?(ignore_entry)
        return false unless ignore_entry["expires"]

        # Handle both string and Date objects
        expires = ignore_entry["expires"]
        expiration_date = expires.is_a?(Date) ? expires : Date.parse(expires.to_s)
        Date.today > expiration_date
      rescue ArgumentError
        # Handle invalid date format, treat as not expired to be safe
        false
      end
    end

    class ConfigError < StandardError; end
  end
end
