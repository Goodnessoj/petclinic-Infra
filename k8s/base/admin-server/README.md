# Admin Server Raw Manifests

This folder is reserved for raw Kubernetes manifests for `admin-server`.

The current YAML files are empty. The active deployment is the
`admin-server-dev` or `admin-server-prod` Argo CD Application, which renders
`helm/petclinic-service` with `helm-values/admin-server.yaml`.
