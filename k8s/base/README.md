# Raw Kubernetes Base

This folder is a placeholder for raw Kubernetes manifests grouped by service and
platform concern.

## Current State

The YAML files in this folder are currently empty. They are not the active
deployment path.

The active application deployment path is:

```text
k8s/argocd/applications -> helm/petclinic-service -> helm-values
```

## Placeholder Folders

- `admin-server`
- `api-gateway`
- `config-server`
- `customers-service`
- `discovery-server`
- `external-secrets`
- `genai-service`
- `ingress`
- `namespaces`
- `vets-service`
- `visits-service`

## If You Reintroduce Raw Manifests

Add a `kustomization.yaml` and keep resources aligned with the Helm chart:

- labels and selectors,
- service names and ports,
- probes,
- environment variables,
- ExternalSecret names,
- PodMonitor labels,
- ALB annotations.

Avoid maintaining two active deployment definitions for the same service unless
there is a clear migration plan.
