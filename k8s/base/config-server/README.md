# Config Server Raw Manifests

This folder is reserved for raw Kubernetes manifests for `config-server`.

The current YAML files are empty. The active deployment is the
`config-server-dev` or `config-server-prod` Argo CD Application, which renders
`helm/petclinic-service` with `helm-values/config-server.yaml`.

`config-server` deploys first because the other services wait for it before
starting.
