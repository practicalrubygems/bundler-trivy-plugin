# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure and foundational code
- Core scanning functionality using Trivy
- Configuration system supporting YAML files and environment variables
- Reporter with terminal output support
- Automatic scanning after `bundle install`
- Support for ignoring CVEs with expiration dates
- CI environment detection for automatic fail-on-critical behavior
- Configurable timeout for Trivy scans
- Severity filtering (CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN)

### Changed
- Migrated from RSpec to Minitest for testing (per Durable Programming standards)
- Moved bundler from development dependency to runtime dependency
- Enhanced gemspec metadata with RubyGems.org requirements

### Documentation
- Created comprehensive TODO.md with improvement roadmap
- Added LICENSE file (MIT)
- Created CHANGELOG.md following Keep a Changelog format
- Added CONTRIBUTING.md with development guidelines
- Added SECURITY.md with vulnerability reporting procedures

## [0.1.0] - 2025-01-31

### Added
- Initial alpha release
- Basic Trivy integration for Bundler
- Configuration file support (`.bundler-trivy.yml`)
- Environment variable configuration
- Vulnerability reporting
- CVE ignore list with expiration

[Unreleased]: https://github.com/durableprogramming/bundler-trivy-plugin/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/durableprogramming/bundler-trivy-plugin/releases/tag/v0.1.0
