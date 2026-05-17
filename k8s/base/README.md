# Raw Kubernetes Base

This folder contains the raw Kubernetes reference manifests that were built
before the active deployment moved to Helm and Argo CD.

## Current State

The base contains Deployments and Services for all eight Petclinic services,
plus namespace and ExternalSecret resources. These manifests are rendered by the
dev and prod Kustomize overlays under `k8s/overlays`.

The active application deployment path is:

```text
k8s/argocd/applications -> helm/petclinic-service -> helm-values
```

## Folders

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

## Deployment Shape

- Services that depend on Config Server and Discovery Server use BusyBox init
  containers to wait for `/actuator/health`.
- Every Deployment has startup, readiness, and liveness probes.
- Config Server uses `/actuator/health` for all probes; the other services use
  `/actuator/health`, `/actuator/health/readiness`, and
  `/actuator/health/liveness`.
- Pod and container security contexts run as non-root, use `RuntimeDefault`
  seccomp, and drop Linux capabilities.

## Render

```bash
kubectl kustomize k8s/overlays/dev
kubectl kustomize k8s/overlays/prod
```

Do not apply these manifests to a namespace already managed by Argo CD Helm
Applications.
