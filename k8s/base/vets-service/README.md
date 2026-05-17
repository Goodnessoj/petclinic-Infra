# Vets Service Raw Manifests

This folder is reserved for raw Kubernetes manifests for `vets-service`.

The current YAML files are empty. The active deployment is the `vets-service-dev`
or `vets-service-prod` Argo CD Application, which renders
`helm/petclinic-service` with `helm-values/vets-service.yaml`.
