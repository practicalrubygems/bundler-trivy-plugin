# Configuration

## Configuration File

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

## Environment Variables

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

## Multiple Environments

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

## Global Configuration

Create `~/.bundle/trivy.yml` for user-wide defaults:

```yaml
# Your personal defaults for all projects
output:
  compact: false
scanning:
  timeout: 180
```

Project configs override global configs.
