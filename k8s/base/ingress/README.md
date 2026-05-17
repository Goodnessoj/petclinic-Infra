# Raw Ingress Manifests

This folder is reserved for raw Kubernetes ingress manifests.

No raw ingress manifest is currently included in the Kustomize base. The active
ingress configuration is rendered by the `petclinic-service` Helm chart for
services such as `api-gateway`, `admin-server`, and `discovery-server`, and by
Terraform add-ons for platform UIs such as Argo CD, Grafana, and Prometheus.
