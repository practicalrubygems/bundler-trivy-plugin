# Troubleshooting

## Plugin not running

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

## Trivy not found

**Verify Trivy is installed**:
```bash
which trivy
trivy --version
```

**Install Trivy**: See [Quick Start](../README.md#quick-start)

## Scan timing out

**Increase timeout**:
```bash
BUNDLER_TRIVY_TIMEOUT=300 bundle install
```

**Or in config**:
```yaml
scanning:
  timeout: 300
```

## False positives

**Ignore specific CVEs temporarily**:
```yaml
ignores:
  - id: CVE-2023-XXXXX
    reason: "Detailed explanation of why this is safe"
    expires: 2025-12-31  # Forces review
```

**Best practice**: Always include an expiration date to force periodic review.

## Scan failing in CI

**Check CI logs for specific error**:
```bash
# Run locally with same settings
CI=true bundle install
```

**Common causes**:
- Outdated Trivy database
- Network connectivity issues
- Actual vulnerabilities (intended behavior!)

## Permission errors

**Linux/macOS**: Ensure Trivy binary is executable:
```bash
chmod +x $(which trivy)
```
