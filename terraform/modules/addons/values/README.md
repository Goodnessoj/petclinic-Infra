# Add-On Values

This folder contains static values files consumed by the Terraform `addons`
module.

## Files

- `monitoring.yaml`: base values for the `kube-prometheus-stack` Helm release.

The Terraform module merges this file with generated values that set Grafana
service type, sidecar discovery labels, Prometheus selectors, and related
environment-specific settings.

## Usage

This file is read from Terraform with:

```hcl
file("${path.module}/values/monitoring.yaml")
```

Edit it for chart-level defaults that should apply to every environment using
the add-ons module. Keep environment-specific values in Terraform variables.
