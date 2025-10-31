# frozen_string_literal: true

require "json"

module Bundler
  module Trivy
    # Formats and displays security scan results to the terminal or JSON.
    #
    # Reporter handles presentation of scan results with multiple output modes:
    # - Terminal output with color-coded severity levels
    # - Compact mode for CI environments
    # - JSON output for machine parsing
    #
    # Terminal output respects the NO_COLOR environment variable and TTY detection.
    #
    # @example Basic usage
    #   reporter = Reporter.new(scan_results, config)
    #   reporter.display
    #
    # @example JSON output
    #   config.json_output = true
    #   reporter = Reporter.new(scan_results, config)
    #   reporter.display # Outputs JSON to stdout
    class Reporter
      # Initializes a new Reporter instance.
      #
      # @param scan_result [ScanResult] The scan results to report
      # @param config [Config, nil] Configuration object for output formatting
      #
      # @example Create reporter
      #   reporter = Reporter.new(scan_results, config)
      def initialize(scan_result, config = nil)
        @result = scan_result
        @config = config || Config.new
      end

      # Displays the scan results according to configuration.
      #
      # Output format depends on configuration:
      # - JSON mode: Outputs machine-readable JSON
      # - No vulnerabilities: Displays success message
      # - Vulnerabilities found: Displays formatted report
      #
      # @return [void]
      #
      # @example Display results
      #   reporter.display
      def display
        if @config.json_output?
          display_json
          return
        end

        if @result.vulnerabilities.empty?
          display_clean_result
          return
        end

        display_summary
        display_vulnerabilities_by_severity
        display_remediation_advice
      end

      private

      def display_clean_result
        ui.confirm "No vulnerabilities found by Trivy"
      end

      def display_summary
        counts = @result.severity_counts

        ui.warn "Trivy found #{@result.vulnerability_count} vulnerabilities"
        puts

        %w[CRITICAL HIGH MEDIUM LOW UNKNOWN].each do |severity|
          count = counts[severity]
          next if count.nil? || count.zero?

          color = color_for_severity(severity)
          puts "  #{send(color, severity)}: #{count}"
        end

        puts
      end

      def display_vulnerabilities_by_severity
        @result.by_severity.sort_by { |sev, _| severity_order(sev) }.each do |severity, vulns|
          next if vulns.empty?
          next if @config.compact_output? && !%w[CRITICAL HIGH].include?(severity)

          puts "#{send(color_for_severity(severity), severity)} Vulnerabilities:"
          puts

          vulns.sort.each do |vuln|
            display_vulnerability(vuln)
          end

          puts
        end
      end

      def display_vulnerability(vuln)
        puts "  #{bold(vuln.package_name)} (#{vuln.installed_version})"
        puts "  #{vuln.id}: #{vuln.title}"

        if vuln.fixable?
          fixed_version = vuln.applicable_fixed_version || vuln.fixed_version
          puts "  Fixed in: #{green(fixed_version)}"
        else
          puts "  #{yellow("No fix available yet")}"
        end

        puts "  #{vuln.primary_url}" if vuln.primary_url
        puts
      end

      def display_remediation_advice
        fixable = @result.vulnerabilities.select(&:fixable?)

        return if fixable.empty?

        puts bold("Recommended Actions:")
        puts

        fixable.group_by(&:package_name).each do |pkg, vulns|
          # Get all fixed versions from all vulnerabilities for this package
          all_versions = vulns.flat_map(&:fixed_versions).compact.uniq
          # Find the maximum version that fixes all vulns (safest upgrade path)
          recommended_version = all_versions.max_by { |v| Gem::Version.new(v) } if all_versions.any?
          if recommended_version
            puts "  Update #{pkg} to #{recommended_version}: bundle update #{pkg}"
          else
            puts "  Update #{pkg}: bundle update #{pkg}"
          end
        end

        puts
      end

      def display_json
        output = {
          vulnerabilities: @result.vulnerabilities.map do |vuln|
            {
              id: vuln.id,
              package: vuln.package_name,
              installed_version: vuln.installed_version,
              fixed_version: vuln.fixed_version,
              severity: vuln.severity,
              title: vuln.title,
              url: vuln.primary_url
            }
          end,
          summary: {
            total: @result.vulnerability_count,
            by_severity: @result.severity_counts
          }
        }

        puts JSON.pretty_generate(output)
      end

      def color_for_severity(severity)
        case severity
        when "CRITICAL" then :red
        when "HIGH" then :red
        when "MEDIUM" then :yellow
        when "LOW" then :blue
        else :default
        end
      end

      def severity_order(severity)
        {"CRITICAL" => 0, "HIGH" => 1, "MEDIUM" => 2, "LOW" => 3, "UNKNOWN" => 4}[severity] || 99
      end

      # Color helpers
      def colorize(text, color_code)
        return text unless color_enabled?

        "\e[#{color_code}m#{text}\e[0m"
      end

      def red(text)
        colorize(text, 31)
      end

      def green(text)
        colorize(text, 32)
      end

      def yellow(text)
        colorize(text, 33)
      end

      def blue(text)
        colorize(text, 34)
      end

      def bold(text)
        colorize(text, 1)
      end

      def default(text)
        text
      end

      def color_enabled?
        return false if ENV["NO_COLOR"]
        return false unless $stdout.tty?

        true
      end

      def ui
        Bundler.ui
      end
    end
  end
end
