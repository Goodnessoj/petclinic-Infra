# API Gateway Raw Manifests

This folder is reserved for raw Kubernetes manifests for `api-gateway`.

The current YAML files are empty. The active deployment is the `api-gateway-dev`
or `api-gateway-prod` Argo CD Application, which renders `helm/petclinic-service`
with `helm-values/api-gateway.yaml`.

`api-gateway` is the public edge service and is the only service values file
with ingress enabled by default.
