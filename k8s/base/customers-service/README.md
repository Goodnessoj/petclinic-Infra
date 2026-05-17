# Customers Service Raw Manifests

This folder is reserved for raw Kubernetes manifests for `customers-service`.

The current YAML files are empty. The active deployment is the
`customers-service-dev` or `customers-service-prod` Argo CD Application, which
renders `helm/petclinic-service` with `helm-values/customers-service.yaml`.
