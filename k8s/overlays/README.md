# Kubernetes Overlays

This folder contains Kustomize overlays for the raw manifests under `k8s/base`.

## Current State

The overlays are reference manifests from the pre-Helm phase. They are not the
active deployment flow, but they render complete dev and prod Kubernetes YAML.

Use the Argo CD and Helm path for current deployments:

```text
k8s/argocd/applications
helm/petclinic-service
helm-values
```

## Overlay Behavior

- `dev`: namespace `petclinic-dev`, one replica, 100m CPU and 256Mi memory
  requests.
- `prod`: namespace `petclinic-prod`, two replicas, 250m CPU and 512Mi memory
  requests, HPAs for API Gateway/customers/visits/vets, and PDBs.

Render:

```bash
kubectl kustomize k8s/overlays/dev
kubectl kustomize k8s/overlays/prod
```
