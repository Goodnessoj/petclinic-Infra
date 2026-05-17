# Helm Charts

This folder contains the reusable Helm charts used to deploy Petclinic runtime
resources.

## Charts

| Chart | Purpose |
| --- | --- |
| [`petclinic-service`](petclinic-service/README.md) | Generic chart for one Spring Petclinic microservice. |
| [`petclinic-secrets`](petclinic-secrets/README.md) | Shared ExternalSecret resources for database and OpenAI runtime secrets. |

## How Values Are Applied

Argo CD applications render service releases from `helm/petclinic-service` and
merge values in this order:

```yaml
valueFiles:
  - ../../helm-values/dev.yaml
  - ../../helm-values/api-gateway.yaml
```

The environment values provide shared defaults. The service values override
image, ports, environment variables, ingress, probes, and service-specific
settings.

The shared secrets chart is installed by GitHub Actions or manually with:

```bash
helm upgrade --install petclinic-secrets helm/petclinic-secrets \
  --namespace petclinic-dev \
  --create-namespace \
  -f helm-values/secrets-dev.yaml
```

## Render Examples

Render a service:

```bash
helm template api-gateway helm/petclinic-service \
  --namespace petclinic-dev \
  -f helm-values/dev.yaml \
  -f helm-values/api-gateway.yaml
```

Render shared secrets:

```bash
helm template petclinic-secrets helm/petclinic-secrets \
  --namespace petclinic-dev \
  -f helm-values/secrets-dev.yaml
```

## Relationship To Argo CD

The Argo CD applications under `k8s/argocd/applications` point at these charts.
The chart source stays in this infrastructure repository so GitOps can reconcile
runtime state directly from committed chart and values changes.
