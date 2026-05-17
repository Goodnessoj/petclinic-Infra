# Admin Server Raw Manifests

This folder contains the raw Kubernetes Deployment and Service for
`admin-server`.

The active deployment is still the
`admin-server-dev` or `admin-server-prod` Argo CD Application, which renders
`helm/petclinic-service` with `helm-values/admin-server.yaml`.
