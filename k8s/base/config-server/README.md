# Config Server Raw Manifests

This folder contains the raw Kubernetes Deployment and Service for
`config-server`.

The active deployment is still the
`config-server-dev` or `config-server-prod` Argo CD Application, which renders
`helm/petclinic-service` with `helm-values/config-server.yaml`.

`config-server` deploys first because the other services wait for it before
starting.
