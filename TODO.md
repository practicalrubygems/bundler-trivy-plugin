# Bundler Trivy Plugin - TODO

Roadmap for production-ready improvements.

## Completed ✓

- ✓ Version management (`lib/bundler/trivy/version.rb`)
- ✓ Complete gemspec metadata
- ✓ Required documentation (CHANGELOG, LICENSE, CONTRIBUTING, SECURITY)
- ✓ Project structure (Rakefile, Gemfile, .gitignore, .rubocop.yml)
- ✓ Basic test infrastructure
- ✓ CI/CD pipeline (.github/workflows)

### 1. Comprehensive Testing Suite
**Goal**: Achieve >90% code coverage

- [ ] Complete unit tests for all classes
- [ ] Add integration tests for full workflow
- [ ] Test edge cases:
  - Trivy not installed
  - Invalid JSON output
  - Timeout scenarios
  - Configuration validation errors
  - Network failures
- [ ] Expand test fixtures
- [ ] Run tests in CI on multiple Ruby versions

### 2. YARD API Documentation
**Goal**: Document all public APIs

- [ ] Add YARD documentation to all public methods
- [ ] Document parameters with `@param` tags
- [ ] Document return values with `@return` tags
- [ ] Document exceptions with `@raise` tags
- [ ] Add usage examples with `@example` tags
- [ ] Generate and publish documentation

### 3. Enhanced Error Handling
**Goal**: Better error messages and recovery

- [ ] Distinguish different Trivy failure types
- [ ] Provide specific remediation steps
- [ ] Add retry logic for transient failures
- [ ] Add debug logging mode
- [ ] Validate config more thoroughly

### 4. README Improvements
**Goal**: Comprehensive user documentation

- [ ] Add troubleshooting section
- [ ] Document all configuration options
- [ ] Add more CI/CD integration examples
- [ ] Add uninstallation instructions
- [ ] Document Trivy version requirements

## Medium Priority

### 5. Enhanced Reporter Output
**Goal**: Better output formatting and formats

- [ ] Add color support with TTY detection
- [ ] Respect `NO_COLOR` environment variable
- [ ] Implement compact mode for CI
- [ ] Add progress indicators
- [ ] Support additional output formats:
  - JSON (machine-readable)
  - JUnit XML (CI integration)
  - SARIF (GitHub Security)
  - Markdown (reports)

### 6. Configuration Templates
**Goal**: Make configuration easier

- [ ] Create `.bundler-trivy.example.yml` with full comments
- [ ] Create `.bundler-trivy.ci.yml` for CI/CD
- [ ] Create `.bundler-trivy.strict.yml` for maximum security
- [ ] Add JSON schema validation for config files

### 7. Release Automation
**Goal**: Streamline releases

- [ ] Automate gem building on tag push
- [ ] Automate RubyGems.org publishing
- [ ] Generate release notes from CHANGELOG
- [ ] Sign releases with GPG

### 8. RubyGems.org Distribution
**Goal**: Make installation easier

- [ ] Publish gem to RubyGems.org
- [ ] Update README with gem installation instructions
- [ ] Add gem badge to README

## Future Enhancements

### 9. Advanced Features

- [ ] Cache Trivy database for faster scans
- [ ] Incremental scanning (only changed dependencies)
- [ ] Fix suggestions via `bundle update`
- [ ] Custom security policies
- [ ] CVE whitelist management commands
- [ ] Integration hooks for custom scripts
- [ ] Dependency tree vulnerability analysis

### 10. Performance Optimizations

- [ ] Profile performance on large projects
- [ ] Parallel scanning for multiple Gemfiles
- [ ] Optimize JSON parsing
- [ ] Scan result caching

### 11. User Experience

- [ ] Interactive mode for vulnerability handling
- [ ] Auto-fix mode for safe updates
- [ ] HTML dashboard/reports
- [ ] Git integration (show which commit added vuln)
- [ ] IDE integration/language server

### 12. Documentation

- [ ] Architecture documentation
- [ ] Video tutorial
- [ ] Blog post announcement
- [ ] Comparison with bundle-audit
- [ ] Migration guide from other tools

### 13. Community

- [ ] GitHub Discussions for Q&A
- [ ] Issue/PR templates
- [ ] Code of conduct
- [ ] Contributor recognition
- [ ] Dependabot configuration

## Pre-1.0 Checklist

- [ ] All public APIs documented with YARD
- [ ] Test coverage >90%
- [ ] All tests passing in CI
- [ ] No RuboCop violations
- [ ] Security audit completed
- [ ] README comprehensive
- [ ] CHANGELOG up to date
- [ ] Installation tested on clean systems
- [ ] Ruby 2.7+ / Bundler 2.0+ compatibility verified
- [ ] No vulnerable dependencies
- [ ] Performance benchmarks documented
