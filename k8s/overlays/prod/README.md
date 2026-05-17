# Prod Overlay

This folder contains the prod Kustomize overlay for the raw Kubernetes reference
manifests.

It renders:

- namespace `petclinic-prod`
- two replicas per service
- 250m CPU and 512Mi memory requests
- prod ECR repository names
- prod Secrets Manager remote secret names
- HPAs for `api-gateway`, `customers-service`, `visits-service`, and
  `vets-service`
- PDBs for all eight services

Render:

```bash
kubectl kustomize k8s/overlays/prod
```

The active prod deployment still runs through manual-sync Argo CD Applications
in `k8s/argocd/applications/prod`.
