# Workflow Files

The YAML files in this folder are the executable GitHub Actions definitions for
the platform.

## File Guide

- `platform.yaml`: Terraform workflow for the platform environments. Manual
  dispatch selects `dev` or `prod` and supports `plan`, `apply`, and
  `destroy`; pull requests and pushes run plan-only checks against `dev`.
  Before Terraform refreshes Kubernetes resources, it ensures the selected EKS
  cluster grants the workflow role cluster-admin access through EKS access
  entries.
- `deploy-argocd.yml`: installs Argo CD, applies Argo CD RBAC, applies the
  Petclinic AppProject and Applications, then optionally waits for health.
- `update-image-tags.yml`: listens for `repository_dispatch` events from the
  application build pipeline and writes new image tags into `helm-values`.
- `deploy-services.yaml`: deploys one or more services directly with Helm. It
  also ensures shared runtime secrets exist before deploying workloads.

## Dependency Order

Both Argo CD and direct Helm deployment respect the service dependency order:

```text
config-server
discovery-server
customers-service
vets-service
visits-service
genai-service
api-gateway
admin-server
```

`config-server` must come first because other services read configuration from
it. `discovery-server` follows because application services register with
Eureka. Edge and admin components deploy after the backing services.
