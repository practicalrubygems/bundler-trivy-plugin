# Security Policy

## Supported Versions

Currently supported versions for security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

As this project matures, we will maintain security support for the latest minor version and critical patches for the previous major version.

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

The security of the Bundler Trivy Plugin is important to us. If you discover a security vulnerability, please report it responsibly.

### How to Report

**Email**: security@durableprogramming.com

**Subject**: `[SECURITY] Bundler Trivy Plugin - Brief description`

### What to Include

Please include the following information in your report:

1. **Description**: Detailed description of the vulnerability
2. **Impact**: Potential impact and severity assessment
3. **Steps to Reproduce**: Exact steps to reproduce the vulnerability
4. **Proof of Concept**: PoC code or exploit (if applicable)
5. **Affected Versions**: Which versions are affected
6. **Suggested Fix**: Your recommendation for fixing (if any)
7. **Your Contact Information**: How we can reach you for follow-up

**Example Report:**

```
Subject: [SECURITY] Bundler Trivy Plugin - Command Injection in Scanner

Description:
The Scanner class does not properly sanitize user-provided paths, allowing
command injection when scanning directories with specially crafted names.

Impact:
HIGH - Allows arbitrary command execution on the host system with the
privileges of the user running bundle install.

Steps to Reproduce:
1. Create a directory named: `test"; rm -rf /tmp/test #`
2. Run bundle install with this directory in the project path
3. Observe command execution during Trivy scan

Affected Versions:
All versions <= 0.1.0

Suggested Fix:
Properly escape or validate directory paths before passing to shell commands.
Use Open3.capture3 with array arguments instead of string interpolation.
```

### What to Expect

- **Response Time**: Within 48 hours of receiving your report
- **Acknowledgment**: Confirmation that we received and are investigating
- **Updates**: Progress updates every 3-5 days
- **Resolution**: We aim to release fixes within 7-14 days for critical issues
- **Disclosure**: Coordinated public disclosure after patch is released
- **Credit**: Public acknowledgment of your contribution (if desired)

## Security Update Process

When a security vulnerability is confirmed:

1. **Assessment**: We evaluate severity and impact
2. **Fix Development**: Develop and test a fix in a private repository
3. **Release Preparation**: Prepare security advisory and patch release
4. **Notification**: Notify affected users before public disclosure (if contact info available)
5. **Patch Release**: Release patched version to RubyGems.org
6. **Public Disclosure**: Publish security advisory on GitHub
7. **Credit**: Acknowledge security researcher (with permission)

## Security Advisories

Security advisories will be published at:
- GitHub Security Advisories: https://github.com/durableprogramming/bundler-trivy-plugin/security/advisories
- Release Notes: Included in CHANGELOG.md with [SECURITY] tag

## Security Best Practices for Users

When using Bundler Trivy Plugin:

### General Recommendations

1. **Keep Updated**: Always use the latest stable version
   ```bash
   bundle plugin update bundler-trivy-plugin
   ```

2. **Review Configuration**: Regularly audit your `.bundler-trivy.yml`
   - Don't ignore vulnerabilities without good reason
   - Set expiration dates on all CVE ignores
   - Use fail-on policies in CI/CD

3. **Monitor Security Advisories**: Subscribe to GitHub security advisories
   - Watch the repository for security updates
   - Enable GitHub Dependabot alerts

4. **Validate Trivy Installation**: Ensure Trivy is from official sources
   ```bash
   # Verify Trivy signature
   trivy --version
   ```

5. **CI/CD Security**: In CI environments, use strict settings
   ```yaml
   # .bundler-trivy.yml
   enabled: true
   fail_on:
     critical: true
     high: true
   ```

### Configuration Security

**Avoid sensitive data in config files:**

```yaml
# Bad - Never put credentials in config
api_token: "secret-token-here"

# Good - Use environment variables
# Then reference ENV["TRIVY_API_TOKEN"] in code
```

**Set appropriate permissions:**

```bash
chmod 600 .bundler-trivy.yml  # Read/write for owner only
```

**Use environment-specific configs:**

```bash
# Development
BUNDLER_TRIVY_ENV=development bundle install

# Production
BUNDLER_TRIVY_ENV=production bundle install
```

### Input Validation

The plugin validates:
- Configuration file syntax (YAML)
- Severity levels
- Date formats for expiration
- Timeout values

But users should still:
- Review configuration before committing
- Use version control for config files
- Audit config changes in pull requests

### Dependency Security

The plugin itself has minimal dependencies:
- `bundler` (runtime dependency)
- `minitest`, `rake`, `rubocop` (development only)

We regularly audit dependencies using:
- `bundle audit` for known vulnerabilities
- Dependabot for automated updates
- Manual review of dependency changes

## Responsible Disclosure

We follow coordinated vulnerability disclosure:

1. **Private Reporting**: Report vulnerabilities privately first
2. **Allow Time to Fix**: Give us reasonable time to patch (typically 90 days)
3. **Coordinated Disclosure**: Agree on disclosure timeline together
4. **Public Credit**: We acknowledge security researchers publicly (with permission)

## Security Scope

### In Scope

Security issues in:
- Plugin code execution and command injection
- Configuration parsing and validation
- Trivy integration and output handling
- File system operations
- Environment variable handling
- Dependency vulnerabilities

### Out of Scope

Issues that are not security vulnerabilities:
- Trivy itself (report to https://github.com/aquasecurity/trivy)
- Bundler core (report to https://github.com/rubygems/bundler)
- Ruby interpreter (report to security@ruby-lang.org)
- User configuration errors
- Feature requests without security impact

## Security Contact

For security issues: security@durableprogramming.com

For general questions: commercial@durableprogramming.com

## Bug Bounty

Currently, we do not have a bug bounty program. However:
- We deeply appreciate security research
- We publicly acknowledge contributors (with permission)
- We may offer swag or recognition for significant findings
- Critical vulnerabilities will be prioritized and fast-tracked

## Past Security Advisories

None at this time. This section will be updated as security issues are discovered and resolved.

---

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Ruby Security Guide](https://guides.rubyonrails.org/security.html)
- [Bundler Security](https://bundler.io/man/bundle-doctor.1.html)
- [Trivy Security](https://trivy.dev/)

Thank you for helping keep Bundler Trivy Plugin and its users safe!
