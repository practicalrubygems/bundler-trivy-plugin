# Bundler Trivy Plugin

**Automated security vulnerability scanning for Ruby dependencies using Trivy.**

A Bundler plugin that automatically integrates [Trivy](https://trivy.dev/) security scanner into your Ruby development workflow. After every `bundle install`, the plugin scans your dependencies for known vulnerabilities and provides actionable remediation guidance.

## Features

- **Automatic Scanning**: Scans dependencies after `bundle install` with zero configuration
- **CI/CD Integration**: Smart defaults for CI environments with configurable fail-on policies
- **Flexible Configuration**: YAML config files and environment variables
- **CVE Ignore List**: Temporary ignore vulnerabilities with expiration dates
- **Multiple Output Formats**: Terminal (default), JSON, and compact modes
- **Detailed Reporting**: Clear vulnerability summaries with fix recommendations
- **Zero Gem Dependencies**: Lightweight plugin with minimal runtime dependencies - none besides other than trivy.

## Quick Start

### 1. Install Trivy

First, install the Trivy scanner:

**macOS**:
```bash
brew install aquasecurity/trivy/trivy
```

**Linux (Ubuntu/Debian)**:
```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

**Other platforms**: See [Trivy Installation Guide](https://trivy.dev/docs/getting-started/installation/)

### 2. Install the Plugin

**From source** (currently):
```bash
gem build bunder-trivy.gemspec
bundle plugin install bunder-trivy --source .
```

**Coming soon - from RubyGems**:
```bash
gem install bunder-trivy
bundle plugin install bunder-trivy
```

### 3. Verify Installation

```bash
bundle plugin list
# Should show: bunder-trivy

trivy --version
# Should show: Version: 0.x.x or later
```

### 4. Use It

That's it! The plugin now runs automatically:

```bash
bundle install
```

## Usage

### Automatic Scanning

The plugin runs automatically after `bundle install`:

```bash
$ bundle install
Fetching gem metadata from https://rubygems.org/
...
Bundle complete! 15 Gemfile dependencies, 73 gems now installed.

⚠ Trivy found 2 vulnerabilities:

  CRITICAL: 1
  HIGH: 1

CRITICAL Vulnerabilities:

  rails (6.1.0)
  CVE-2023-38545: Rails ActiveRecord SQL Injection
  Fixed in: 6.1.7.6, 7.0.8
  https://avd.aquasec.com/nvd/cve-2023-38545

Recommended Actions:

  Update rails: bundle update rails
```

### Skipping Scans

Temporarily skip scanning:

```bash
BUNDLER_TRIVY_SKIP=true bundle install
```

### CI/CD Integration

The plugin automatically detects CI environments and enables strict mode:

```yaml
# GitHub Actions example
- name: Install dependencies
  run: bundle install
  # Plugin automatically fails on critical vulnerabilities in CI

# Override if needed
- name: Install dependencies (non-blocking)
  run: BUNDLER_TRIVY_FAIL_ON_CRITICAL=false bundle install
```

**Supported CI platforms**:
- GitHub Actions
- GitLab CI
- Travis CI
- Jenkins
- CircleCI (via CI=true)

## Configuration

### Configuration File

Create `.bundler-trivy.yml` in your project root:

```yaml
# Enable/disable scanning (default: true)
enabled: true

# Fail conditions - exit with error code 1 if vulnerabilities found
fail_on:
  critical: true  # Default: true in CI, false locally
  high: false     # Default: false
  # Note: BUNDLER_TRIVY_FAIL_ON_ANY=true fails on any severity

# Output configuration
output:
  format: terminal  # Options: terminal, json
  compact: false    # Default: false locally, true in CI

# Scanning configuration
scanning:
  timeout: 120  # Scan timeout in seconds (default: 120)
  severity_filter:
    - CRITICAL
    - HIGH
    # Options: CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN

# Ignore specific CVEs (use sparingly!)
ignores:
  - id: CVE-2023-12345
    reason: "False positive - does not affect our usage pattern"
    expires: 2025-12-31  # Required: forces periodic review

  - id: CVE-2023-67890
    reason: "Waiting for backport to current Rails version"
    expires: 2025-06-30
```

### Environment Variables

Environment variables override configuration file settings:

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `BUNDLER_TRIVY_SKIP` | Skip scanning entirely | `false` | `true` |
| `BUNDLER_TRIVY_FAIL_ON_CRITICAL` | Exit on critical vulns | CI=true | `true` |
| `BUNDLER_TRIVY_FAIL_ON_HIGH` | Exit on high vulns | `false` | `true` |
| `BUNDLER_TRIVY_FAIL_ON_ANY` | Exit on any vulns | `false` | `true` |
| `BUNDLER_TRIVY_COMPACT` | Compact output | CI=true | `true` |
| `BUNDLER_TRIVY_FORMAT` | Output format | `terminal` | `json` |
| `BUNDLER_TRIVY_TIMEOUT` | Scan timeout (seconds) | `120` | `300` |
| `BUNDLER_TRIVY_SEVERITY` | Severity threshold | `CRITICAL` | `HIGH` |

**Examples**:

```bash
# Ultra-strict mode (fail on any vulnerability)
BUNDLER_TRIVY_FAIL_ON_ANY=true bundle install

# JSON output for parsing
BUNDLER_TRIVY_FORMAT=json bundle install > vulnerabilities.json

# Longer timeout for large projects
BUNDLER_TRIVY_TIMEOUT=300 bundle install

# Skip scanning temporarily
BUNDLER_TRIVY_SKIP=true bundle install
```

### Multiple Environments

Use environment-specific configs:

```bash
# .bundler-trivy.development.yml - lenient for local dev
enabled: true
fail_on:
  critical: false

# .bundler-trivy.production.yml - strict for production
enabled: true
fail_on:
  critical: true
  high: true
```

Activate with:

```bash
BUNDLER_TRIVY_ENV=production bundle install
```

### Global Configuration

Create `~/.bundle/trivy.yml` for user-wide defaults:

```yaml
# Your personal defaults for all projects
output:
  compact: false
scanning:
  timeout: 180
```

Project configs override global configs.

## Examples

### Example: GitHub Actions Workflow

```yaml
name: Security Scan

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: false  # We'll handle bundling

      - name: Install Trivy
        run: |
          wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
          echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
          sudo apt-get update
          sudo apt-get install trivy

      - name: Install Plugin
        run: |
          gem build bunder-trivy.gemspec
          bundle plugin install bunder-trivy --source .

      - name: Install Dependencies with Security Scan
        run: bundle install
        # Automatically fails on critical vulnerabilities in CI
```

### Example: GitLab CI

```yaml
security_scan:
  image: ruby:3.2
  before_script:
    - apt-get update && apt-get install -y wget gnupg
    - wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
    - echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
    - apt-get update && apt-get install -y trivy
    - gem build bunder-trivy.gemspec
    - bundle plugin install bunder-trivy --source .
  script:
    - bundle install
  allow_failure: false
```

### Example: Local Development Workflow

```bash
# Initial setup
bundle install  # Scans and warns about vulnerabilities

# Working on features (skip scanning for speed)
BUNDLER_TRIVY_SKIP=true bundle install

# Before committing (strict check)
BUNDLER_TRIVY_FAIL_ON_HIGH=true bundle install
```

## Troubleshooting

### Plugin not running

**Check plugin is installed**:
```bash
bundle plugin list
# Should show bunder-trivy
```

**Reinstall if needed**:
```bash
bundle plugin uninstall bunder-trivy
bundle plugin install bunder-trivy --source .
```

### Trivy not found

**Verify Trivy is installed**:
```bash
which trivy
trivy --version
```

**Install Trivy**: See [Quick Start](#quick-start)

### Scan timing out

**Increase timeout**:
```bash
BUNDLER_TRIVY_TIMEOUT=300 bundle install
```

**Or in config**:
```yaml
scanning:
  timeout: 300
```

### False positives

**Ignore specific CVEs temporarily**:
```yaml
ignores:
  - id: CVE-2023-XXXXX
    reason: "Detailed explanation of why this is safe"
    expires: 2025-12-31  # Forces review
```

**Best practice**: Always include an expiration date to force periodic review.

### Scan failing in CI

**Check CI logs for specific error**:
```bash
# Run locally with same settings
CI=true bundle install
```

**Common causes**:
- Outdated Trivy database
- Network connectivity issues
- Actual vulnerabilities (intended behavior!)

### Permission errors

**Linux/macOS**: Ensure Trivy binary is executable:
```bash
chmod +x $(which trivy)
```

## Development

### Setup

```bash
git clone https://github.com/durableprogramming/bunder-trivy.git
cd bunder-trivy
bundle install
```

### Running Tests

```bash
# Run all tests
rake test

# Run specific test file
ruby test/bundler/trivy/config_test.rb

# Run with coverage
COVERAGE=true rake test
```

### Code Quality

```bash
# Check style
bundle exec rubocop

# Auto-fix violations
bundle exec rubocop -a
```

### Local Testing

```bash
# Build gem
gem build bunder-trivy.gemspec

# Install in test project
cd /path/to/test/project
bundle plugin uninstall bunder-trivy || true
bundle plugin install bunder-trivy --source /path/to/plugin

# Test
bundle install
```

### Opening Console

```bash
rake console
```

## Requirements

- **Ruby**: 2.7.0 or later
- **Bundler**: 2.0 or later
- **Trivy**: Latest version recommended (0.40.0+)
- **Operating Systems**: macOS, Linux, Windows (with WSL)

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Code style guidelines
- Testing requirements
- Pull request process

## Security

Security is paramount. See [SECURITY.md](SECURITY.md) for:
- Vulnerability reporting procedures
- Security best practices
- Supported versions

**Report security issues to**: security@durableprogramming.com

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

## Roadmap

See [TODO.md](TODO.md) for planned features and improvements.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- **Documentation**: [GitHub README](https://github.com/durableprogramming/bunder-trivy)
- **Issues**: [GitHub Issues](https://github.com/durableprogramming/bunder-trivy/issues)
- **Email**: commercial@durableprogramming.com

## Credits

- Built by [Durable Programming LLC](https://durableprogramming.com)
- Powered by [Aqua Security Trivy](https://trivy.dev/)
- Inspired by the Ruby security community

---

**Stay secure!** 🔒
