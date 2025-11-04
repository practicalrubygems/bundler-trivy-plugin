# Development

## Setup

```bash
git clone https://github.com/durableprogramming/bunder-trivy.git
cd bunder-trivy
bundle install
```

## Running Tests

```bash
# Run all tests
rake test

# Run specific test file
ruby test/bundler/trivy/config_test.rb

# Run with coverage
COVERAGE=true rake test
```

## Code Quality

```bash
# Check style
bundle exec rubocop

# Auto-fix violations
bundle exec rubocop -a
```

## Local Testing

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

## Opening Console

```bash
rake console
```
