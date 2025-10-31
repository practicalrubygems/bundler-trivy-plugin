# frozen_string_literal: true

require "test_helper"

module Bundler
  module Trivy
    class VersionTest < Minitest::Test
      def test_version_constant_is_defined
        assert defined?(VERSION)
      end

      def test_version_is_a_string
        assert_kind_of String, VERSION
      end

      def test_version_matches_semantic_version_format
        # Basic semantic version pattern: major.minor.patch
        assert_match(/^\d+\.\d+\.\d+$/, VERSION)
      end
    end
  end
end
