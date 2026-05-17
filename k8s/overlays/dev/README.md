# Dev Overlay

This folder contains the dev Kustomize overlay for the raw Kubernetes reference
manifests.

It renders:

- namespace `petclinic-dev`
- one replica per service
- 100m CPU and 256Mi memory requests
- dev ECR repository names
- dev Secrets Manager remote secret names

Render:

```bash
kubectl kustomize k8s/overlays/dev
```

The active dev deployment still runs through Argo CD Applications in:

```text
k8s/argocd/applications/dev
```

Those Applications render:

```text
helm/petclinic-service
helm-values/dev.yaml
helm-values/<service>.yaml
```
