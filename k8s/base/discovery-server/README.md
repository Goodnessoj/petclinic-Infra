# Discovery Server Raw Manifests

This folder contains the raw Kubernetes Deployment and Service for
`discovery-server`.

The active deployment is still the
`discovery-server-dev` or `discovery-server-prod` Argo CD Application, which
renders `helm/petclinic-service` with `helm-values/discovery-server.yaml`.

Application services point Eureka clients at this service.
