# frozen_string_literal: true

require_relative "vulnerability"

module Bundler
  module Trivy
    # Represents the results of a Trivy security scan.
    #
    # ScanResult wraps the raw JSON output from Trivy and provides convenient
    # methods for accessing vulnerability information, filtering by severity,
    # grouping vulnerabilities, and generating summaries. It automatically
    # filters out ignored CVEs based on configuration.
    #
    # @example Basic usage
    #   results = scanner.scan
    #   puts "Found #{results.vulnerability_count} vulnerabilities"
    #   puts "Critical: #{results.critical_vulnerabilities.count}"
    #
    # @example Filtering by severity
    #   critical_vulns = results.critical_vulnerabilities
    #   critical_vulns.each do |vuln|
    #     puts "#{vuln.id}: #{vuln.package_name}"
    #   end
    #
    # @example Grouping vulnerabilities
    #   results.by_severity.each do |severity, vulns|
    #     puts "#{severity}: #{vulns.count} vulnerabilities"
    #   end
    class ScanResult
      # @return [Hash] Raw Trivy scan data
      attr_reader :data

      # Initializes a new ScanResult instance.
      #
      # @param data [Hash] Raw JSON data from Trivy scan
      # @param config [Config, nil] Configuration object for filtering ignored CVEs
      #
      # @example Create from scan data
      #   data = JSON.parse(trivy_output)
      #   results = ScanResult.new(data, config)
      def initialize(data, config = nil)
        @data = data || {}
        @config = config
      end

      # Returns all vulnerabilities found in the scan.
      #
      # Vulnerabilities are wrapped in Vulnerability objects for convenient access.
      # CVEs marked as ignored in the configuration are automatically filtered out.
      #
      # @return [Array<Vulnerability>] Array of vulnerability objects
      #
      # @example Get all vulnerabilities
      #   results.vulnerabilities.each do |vuln|
      #     puts "#{vuln.severity}: #{vuln.package_name} - #{vuln.id}"
      #   end
      def vulnerabilities
        results = @data["Results"] || []

        results.flat_map do |result|
          vulns = result["Vulnerabilities"]
          next [] if vulns.nil? || vulns.empty?

          vulns.map { |v| Vulnerability.new(v, result["Target"]) }
        end.compact.reject { |v| ignored?(v) }
      end

      # Groups vulnerabilities by severity level.
      #
      # @return [Hash<String, Array<Vulnerability>>] Hash with severity levels as keys
      #
      # @example Group by severity
      #   results.by_severity.each do |severity, vulns|
      #     puts "#{severity}: #{vulns.count}"
      #   end
      def by_severity
        vulnerabilities.group_by(&:severity)
      end

      # Returns only CRITICAL severity vulnerabilities.
      #
      # @return [Array<Vulnerability>] Array of critical vulnerabilities
      #
      # @example Get critical vulnerabilities
      #   critical = results.critical_vulnerabilities
      #   puts "#{critical.count} critical issues found"
      def critical_vulnerabilities
        vulnerabilities.select(&:critical?)
      end

      # Returns only HIGH severity vulnerabilities.
      #
      # @return [Array<Vulnerability>] Array of high severity vulnerabilities
      def high_vulnerabilities
        vulnerabilities.select(&:high?)
      end

      # Checks if any vulnerabilities were found.
      #
      # @return [Boolean] true if vulnerabilities exist
      #
      # @example Check for vulnerabilities
      #   if results.has_vulnerabilities?
      #     puts "Security issues detected!"
      #   end
      def has_vulnerabilities?
        !vulnerabilities.empty?
      end

      # Checks if any CRITICAL severity vulnerabilities were found.
      #
      # This is useful for implementing fail-on-critical policies.
      #
      # @return [Boolean] true if critical vulnerabilities exist
      #
      # @example Fail on critical
      #   exit 1 if results.has_critical_vulnerabilities?
      def has_critical_vulnerabilities?
        !critical_vulnerabilities.empty?
      end

      # Returns the total count of all vulnerabilities.
      #
      # @return [Integer] Total vulnerability count
      #
      # @example Get total count
      #   puts "Total: #{results.vulnerability_count}"
      def vulnerability_count
        vulnerabilities.size
      end

      # Returns vulnerability counts grouped by severity level.
      #
      # @return [Hash<String, Integer>] Hash with severity levels as keys and counts as values
      #
      # @example Get severity breakdown
      #   counts = results.severity_counts
      #   # => {"CRITICAL" => 2, "HIGH" => 5, "MEDIUM" => 10}
      def severity_counts
        by_severity.transform_values(&:size)
      end

      private

      # Checks if a vulnerability should be ignored based on configuration.
      #
      # @param vulnerability [Vulnerability] The vulnerability to check
      # @return [Boolean] true if the vulnerability should be ignored
      def ignored?(vulnerability)
        return false unless @config

        @config.cve_ignored?(vulnerability.id)
      end
    end
  end
end
