# Kubernetes Overlays

This folder is reserved for future Kustomize overlays that would customize the
raw manifests under `k8s/base`.

## Current State

The overlay tree is currently empty and is not part of the active deployment
flow.

Use the Argo CD and Helm path for current deployments:

```text
k8s/argocd/applications
helm/petclinic-service
helm-values
```

## Expected Future Use

If raw Kubernetes manifests are reintroduced, overlays can hold
environment-specific patches such as:

- replica counts,
- image tags,
- ingress hosts,
- resource requests and limits,
- secret references,
- monitoring labels.
