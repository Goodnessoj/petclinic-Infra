# Customers Service Raw Manifests

This folder contains the raw Kubernetes Deployment and Service for
`customers-service`.

The active deployment is still the
`customers-service-dev` or `customers-service-prod` Argo CD Application, which
renders `helm/petclinic-service` with `helm-values/customers-service.yaml`.
