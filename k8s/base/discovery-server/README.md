# Discovery Server Raw Manifests

This folder is reserved for raw Kubernetes manifests for `discovery-server`.

The current YAML files are empty. The active deployment is the
`discovery-server-dev` or `discovery-server-prod` Argo CD Application, which
renders `helm/petclinic-service` with `helm-values/discovery-server.yaml`.

Application services point Eureka clients at this service.
