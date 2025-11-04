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

**NixOS/home-manager**:
```nix
# In configuration.nix or home.nix
environment.systemPackages = [ pkgs.trivy ];
# Or for home-manager:
home.packages = [ pkgs.trivy ];
```

**Other platforms**: See [Trivy Installation Guide](https://trivy.dev/docs/getting-started/installation/)

### 2. Install the Plugin


**From RubyGems**:
```bash
gem install bunder-trivy
bundle plugin install bunder-trivy
```

**From source**:
```bash
git clone https://github.com/practicalrubygems/bundler-trivy-plugin
cd bundler-trivy-plugin
gem build
bundle plugin install bunder-trivy --source .
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

The plugin supports flexible configuration via YAML files and environment variables. See the [Configuration Guide](docs/configuration.md) for complete details on:
- Configuration file options
- Environment variables
- Multiple environment configs
- Global user settings

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

Having issues? See the [Troubleshooting Guide](docs/troubleshooting.md) for common problems and solutions.

## Development

Want to contribute? See the [Development Guide](docs/development.md) for setup instructions, testing, and local development workflows.

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
