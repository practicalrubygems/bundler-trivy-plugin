# frozen_string_literal: true

require "test_helper"

module Bundler
  module Trivy
    class PluginTest < Minitest::Test
      def setup
        super
        @temp_dir = create_temp_dir
        create_sample_lockfile(@temp_dir)
        @original_lockfile = ENV.fetch("BUNDLE_GEMFILE", nil)
        ENV["BUNDLE_GEMFILE"] = File.join(@temp_dir, "Gemfile")
      end

      def teardown
        super
        FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
        ENV["BUNDLE_GEMFILE"] = @original_lockfile
      end

      def test_scan_after_install_skips_when_config_skip_scan_true
        config_mock = Minitest::Mock.new
        config_mock.expect :skip_scan?, true

        Config.stub :new, config_mock do
          # Should return early without doing anything
          Plugin.scan_after_install
        end

        config_mock.verify
      end

      def test_scan_after_install_warns_when_gemfile_lock_missing
        config_mock = Minitest::Mock.new
        config_mock.expect :skip_scan?, false

        Bundler.stub :default_lockfile, Pathname.new("/nonexistent/Gemfile.lock") do
          Config.stub :new, config_mock do
            ui_mock = Minitest::Mock.new
            ui_mock.expect :warn, nil, ["Gemfile.lock not found, skipping scan"]

            Bundler.stub :ui, ui_mock do
              Plugin.scan_after_install
            end
          end
        end

        config_mock.verify
      end

      def test_scan_after_install_warns_when_trivy_not_available
        config_mock = Minitest::Mock.new
        config_mock.expect :skip_scan?, false

        scanner_mock = Minitest::Mock.new
        scanner_mock.expect :trivy_available?, false

        Config.stub :new, config_mock do
          Scanner.stub :new, scanner_mock do
            ui_mock = Minitest::Mock.new
            ui_mock.expect :warn, nil, ["Trivy not found, skipping scan"]
            ui_mock.expect :info, nil, ["Install: https://trivy.dev/docs/getting-started/installation/"]

            Bundler.stub :ui, ui_mock do
              Plugin.scan_after_install
            end
          end
        end

        config_mock.verify
        scanner_mock.verify
      end

      def test_scan_after_install_runs_successful_scan
        config_mock = Minitest::Mock.new
        config_mock.expect :skip_scan?, false

        scanner_mock = Minitest::Mock.new
        scanner_mock.expect :trivy_available?, true

        results_mock = Minitest::Mock.new
        scanner_mock.expect :scan, results_mock

        reporter_mock = Minitest::Mock.new
        reporter_mock.expect :display, nil

        Config.stub :new, config_mock do
          Scanner.stub :new, scanner_mock do
            Reporter.stub :new, reporter_mock do
              Plugin.stub :handle_exit_code, nil do
                Plugin.scan_after_install
              end
            end
          end
        end

        config_mock.verify
        scanner_mock.verify
        reporter_mock.verify
      end

      def test_scan_after_install_handles_scan_exceptions
        config_mock = Minitest::Mock.new
        config_mock.expect :skip_scan?, false

        scanner_mock = Minitest::Mock.new
        scanner_mock.expect :trivy_available?, true

        def scanner_mock.scan
          raise StandardError.new("Scan failed")
        end

        Config.stub :new, config_mock do
          Scanner.stub :new, scanner_mock do
            ui_mock = Minitest::Mock.new
            ui_mock.expect :warn, nil, ["Trivy scan failed: Scan failed"]

            Bundler.stub :ui, ui_mock do
              # Should not raise
              Plugin.scan_after_install
            end
          end
        end

        config_mock.verify
        scanner_mock.verify
      end

      def test_handle_exit_code_does_not_exit_when_no_critical_vulns
        config_mock = Minitest::Mock.new
        config_mock.expect :fail_on_any?, false

        results_mock = Minitest::Mock.new
        results_mock.expect :has_critical_vulnerabilities?, false
        results_mock.expect :has_vulnerabilities?, true

        # Should not call exit
        Plugin.handle_exit_code(results_mock, config_mock)

        config_mock.verify
        results_mock.verify
      end

      def test_handle_exit_code_exits_on_critical_vulns_when_configured
        config_mock = Minitest::Mock.new
        config_mock.expect :fail_on_critical?, true

        results_mock = Minitest::Mock.new
        results_mock.expect :has_critical_vulnerabilities?, true

        ui_mock = Minitest::Mock.new
        ui_mock.expect :error, nil, ["CRITICAL vulnerabilities found. Install blocked."]

        Bundler.stub :ui, ui_mock do
          assert_raises(SystemExit) do
            Plugin.handle_exit_code(results_mock, config_mock)
          end
        end

        config_mock.verify
        results_mock.verify
      end

      def test_handle_exit_code_exits_on_any_vulns_when_configured
        config_mock = Minitest::Mock.new
        config_mock.expect :fail_on_any?, true

        results_mock = Minitest::Mock.new
        results_mock.expect :has_critical_vulnerabilities?, false
        results_mock.expect :has_vulnerabilities?, true

        ui_mock = Minitest::Mock.new
        ui_mock.expect :error, nil, ["Vulnerabilities found. Install blocked."]

        Bundler.stub :ui, ui_mock do
          assert_raises(SystemExit) do
            Plugin.handle_exit_code(results_mock, config_mock)
          end
        end

        config_mock.verify
        results_mock.verify
      end

      def test_handle_exit_code_prioritizes_critical_over_any
        config_mock = Minitest::Mock.new
        config_mock.expect :fail_on_critical?, true

        results_mock = Minitest::Mock.new
        results_mock.expect :has_critical_vulnerabilities?, true

        ui_mock = Minitest::Mock.new
        ui_mock.expect :error, nil, ["CRITICAL vulnerabilities found. Install blocked."]

        Bundler.stub :ui, ui_mock do
          assert_raises(SystemExit) do
            Plugin.handle_exit_code(results_mock, config_mock)
          end
        end

        config_mock.verify
        results_mock.verify
      end

      def test_handle_exit_code_does_not_exit_when_no_vulnerabilities
        config_mock = Minitest::Mock.new

        results_mock = Minitest::Mock.new
        results_mock.expect :has_critical_vulnerabilities?, false
        results_mock.expect :has_vulnerabilities?, false

        # Should not call exit or ui.error
        Plugin.handle_exit_code(results_mock, config_mock)

        config_mock.verify
        results_mock.verify
      end

      def test_scan_after_install_shows_backtrace_when_debug_set
        config_mock = Minitest::Mock.new
        config_mock.expect :skip_scan?, false

        scanner_mock = Minitest::Mock.new
        scanner_mock.expect :trivy_available?, true

        def scanner_mock.scan
          exception = StandardError.new("Scan failed")
          exception.set_backtrace(["line1", "line2"])
          raise exception
        end

        Config.stub :new, config_mock do
          Scanner.stub :new, scanner_mock do
            ui_mock = Minitest::Mock.new
            ui_mock.expect :warn, nil, ["Trivy scan failed: Scan failed"]
            ui_mock.expect :debug, nil, ["line1\nline2"]

            Bundler.stub :ui, ui_mock do
              ENV["DEBUG"] = "1"
              begin
                Plugin.scan_after_install
              ensure
                ENV.delete("DEBUG")
              end
            end
          end
        end

        config_mock.verify
        scanner_mock.verify
      end

      def test_scan_after_install_handles_ui_warn_exception
        config_mock = Minitest::Mock.new
        config_mock.expect :skip_scan?, false

        scanner_mock = Minitest::Mock.new
        scanner_mock.expect :trivy_available?, false

        Config.stub :new, config_mock do
          Scanner.stub :new, scanner_mock do
            ui_mock = Minitest::Mock.new
            ui_mock.expect :warn, nil, ["Trivy not found, skipping scan"]
            ui_mock.expect :info, nil do
              raise StandardError.new("UI error")
            end

            Bundler.stub :ui, ui_mock do
              # Should not raise, even if UI methods fail
              Plugin.scan_after_install
            end
          end
        end

        config_mock.verify
        scanner_mock.verify
      end
    end
  end
end
