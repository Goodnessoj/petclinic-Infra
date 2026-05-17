# API Gateway Raw Manifests

This folder contains the raw Kubernetes Deployment and Service for
`api-gateway`.

The active deployment is still the `api-gateway-dev`
or `api-gateway-prod` Argo CD Application, which renders `helm/petclinic-service`
with `helm-values/api-gateway.yaml`.

`api-gateway` is the public edge service.
