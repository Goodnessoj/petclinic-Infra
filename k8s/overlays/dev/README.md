# Dev Overlay

This folder is reserved for a future dev Kustomize overlay.

It is currently empty and not used by the active deployment flow. Dev services
are deployed through Argo CD Applications in:

```text
k8s/argocd/applications/dev
```

Those Applications render:

```text
helm/petclinic-service
helm-values/dev.yaml
helm-values/<service>.yaml
```
