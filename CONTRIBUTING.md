# Contributing to Bundler Trivy Plugin

Thank you for your interest in contributing to the Bundler Trivy Plugin! This document provides guidelines for contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Code Review Guidelines](#code-review-guidelines)
- [Reporting Issues](#reporting-issues)

## Getting Started

### Prerequisites

- Ruby 2.7.0 or higher
- Bundler 2.0 or higher
- Trivy (for testing scanner functionality)
- Git

### Development Setup

1. **Fork and clone the repository**

```bash
git clone https://github.com/YOUR_USERNAME/bundler-trivy-plugin.git
cd bundler-trivy-plugin
```

2. **Install dependencies**

```bash
bundle install
```

3. **Install Trivy** (if not already installed)

```bash
# macOS
brew install aquasecurity/trivy/trivy

# Linux
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

4. **Run tests to verify setup**

```bash
rake test
```

5. **Create a feature branch**

```bash
git checkout -b feature/your-feature-name
```

## Development Workflow

### Making Changes

1. Make your changes in your feature branch
2. Add tests for new functionality
3. Run the full test suite to ensure nothing breaks
4. Update documentation as needed
5. Commit with clear, descriptive messages
6. Push to your fork and create a pull request

### Testing Your Changes Locally

To test the plugin in a real project:

```bash
# Build the gem
gem build bundler-trivy-plugin.gemspec

# Uninstall existing version (if any)
bundle plugin uninstall bundler-trivy-plugin

# Install from local source
bundle plugin install bundler-trivy-plugin --source .

# Test in a sample project
cd /path/to/test/project
bundle install
```

## Code Standards

### Style Guide

This project follows [RuboCop](https://rubocop.org/) style guidelines with custom configurations.

**Run the linter:**

```bash
bundle exec rubocop
```

**Auto-fix violations:**

```bash
bundle exec rubocop -a
```

### Code Conventions

- Use `frozen_string_literal: true` at the top of all Ruby files
- Follow Ruby naming conventions:
  - `snake_case` for methods and variables
  - `PascalCase` for classes and modules
  - `SCREAMING_SNAKE_CASE` for constants
- Keep methods focused and small (prefer < 15 lines)
- Use meaningful variable and method names
- Avoid abbreviations unless widely understood

### Documentation Standards

- Add YARD documentation to all public methods
- Include `@param`, `@return`, and `@raise` tags
- Provide usage examples with `@example` tags
- Document complex logic with inline comments
- Update README.md for user-facing changes

**Example:**

```ruby
# Executes a Trivy security scan on the project's dependencies.
#
# This method runs Trivy in JSON output mode and parses the results
# into a structured ScanResult object for programmatic access.
#
# @return [ScanResult] Parsed scan results with vulnerability information
# @raise [ScanError] If Trivy execution fails or produces invalid output
# @raise [Timeout::Error] If scan exceeds configured timeout
#
# @example Scanning the current project
#   scanner = Scanner.new("/path/to/project")
#   results = scanner.scan
#   puts "Found #{results.vulnerability_count} vulnerabilities"
def scan
  # Implementation
end
```

## Testing Requirements

### Test Framework

This project uses [Minitest](https://github.com/minitest/minitest) for testing.

### Writing Tests

- Create test files in the `test/` directory matching the structure of `lib/`
- Name test files with `_test.rb` suffix (e.g., `config_test.rb`)
- Each test class should inherit from `Minitest::Test`
- Use descriptive test method names starting with `test_`

**Example test structure:**

```ruby
require "test_helper"

module Bundler
  module Trivy
    class ConfigTest < Minitest::Test
      def setup
        @config = Config.new
      end

      def test_skip_scan_returns_false_by_default
        refute @config.skip_scan?
      end

      def test_fail_on_critical_in_ci_environment
        ENV["CI"] = "true"
        assert @config.fail_on_critical?
      ensure
        ENV.delete("CI")
      end
    end
  end
end
```

### Test Coverage

- Aim for >90% code coverage
- All public methods must have tests
- Test both success and failure paths
- Include edge cases and boundary conditions
- Test configuration variations

### Running Tests

```bash
# Run all tests
rake test

# Run a specific test file
ruby test/bundler/trivy/config_test.rb

# Run with coverage report
COVERAGE=true rake test
```

## Documentation

### README Updates

When adding features, update the README with:
- New configuration options
- Usage examples
- Prerequisites or dependencies

### CHANGELOG Updates

Document all changes in CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/):

- Add entries under `[Unreleased]` section
- Use appropriate categories: Added, Changed, Deprecated, Removed, Fixed, Security
- Be concise but descriptive
- Reference issue numbers where applicable

## Pull Request Process

### Before Submitting

Ensure your pull request meets these requirements:

- [ ] All tests pass locally (`rake test`)
- [ ] Code follows style guide (`rubocop`)
- [ ] Documentation is updated (README, YARD comments)
- [ ] CHANGELOG.md is updated
- [ ] Commit messages are clear and descriptive
- [ ] Branch is up-to-date with main

### PR Description

Provide a clear description that includes:

1. **What**: Brief summary of changes
2. **Why**: Motivation and context
3. **How**: Technical approach (if complex)
4. **Testing**: How you tested the changes
5. **Screenshots**: If UI/output changes (use code blocks for terminal output)
6. **Breaking Changes**: Highlight any breaking changes
7. **Related Issues**: Link to related issues using `Fixes #123` or `Closes #456`

**Example PR template:**

```markdown
## What

Adds JSON output format support to the reporter.

## Why

Users need machine-readable output for CI/CD integration and automated processing.

## How

- Added `--format json` option to config
- Implemented JSON serialization in Reporter class
- Updated Scanner to support format parameter

## Testing

- Added unit tests for JSON reporter
- Tested with sample vulnerability data
- Verified in CI environment

## Example Output

\```json
{
  "vulnerabilities": [...],
  "summary": {...}
}
\```

Fixes #42
```

### Review Process

1. Maintainers will review your PR within 3-5 business days
2. Address feedback and requested changes
3. Update your PR by pushing to the same branch
4. Once approved, maintainers will merge your PR
5. Your contribution will be included in the next release

## Code Review Guidelines

### What Reviewers Look For

- **Correctness**: Does the code work as intended?
- **Tests**: Are there adequate tests with good coverage?
- **Documentation**: Is the code well-documented?
- **Style**: Does it follow project conventions?
- **Performance**: Are there performance implications?
- **Security**: Are there security concerns?
- **Maintainability**: Is the code easy to understand and modify?

### Providing Feedback

When reviewing:
- Be constructive and respectful
- Explain the reasoning behind suggestions
- Distinguish between blocking issues and suggestions
- Acknowledge good work

## Reporting Issues

### Bug Reports

When reporting bugs, include:

- **Description**: Clear description of the issue
- **Steps to Reproduce**: Exact steps to reproduce the problem
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**:
  - Ruby version (`ruby --version`)
  - Bundler version (`bundle --version`)
  - Trivy version (`trivy --version`)
  - Operating system
- **Gemfile.lock**: Relevant portions (if applicable)
- **Configuration**: Your `.bundler-trivy.yml` (sanitized)
- **Error Messages**: Full error output and stack traces

### Feature Requests

For feature requests, include:

- **Use Case**: Describe the problem you're trying to solve
- **Proposed Solution**: Your suggested implementation
- **Alternatives Considered**: Other approaches you've thought about
- **Impact**: Who would benefit and how

### Security Vulnerabilities

**Do not report security vulnerabilities through public GitHub issues.**

Please report security issues to: security@durableprogramming.com

See [SECURITY.md](SECURITY.md) for details.

## Questions?

- **Documentation**: Check the [README](README.md) and inline documentation
- **GitHub Discussions**: Ask questions in [Discussions](https://github.com/durableprogramming/bundler-trivy-plugin/discussions)
- **Email**: For private inquiries, contact commercial@durableprogramming.com

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Code of Conduct

Please note that this project adheres to a Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to commercial@durableprogramming.com.

---

Thank you for contributing to Bundler Trivy Plugin! Your efforts help make Ruby applications more secure.
