# Integration Test Application

This is a simple test application to verify the Trivy Bundler plugin functionality.

## Setup

```bash
cd integration-test
bundle install
```

## Testing the Plugin

```bash
# Install the plugin locally
bundle plugin install bundler-trivy --source=..

# Run Trivy scan
bundle trivy
```
