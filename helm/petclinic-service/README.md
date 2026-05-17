# Petclinic Service Chart

`petclinic-service` is a generic Helm chart for deploying one Spring Petclinic
microservice.

## Resources Rendered

Depending on values, the chart can render:

- Deployment
- ServiceAccount
- Service
- ConfigMap
- ExternalSecret
- HorizontalPodAutoscaler
- PodDisruptionBudget
- PodMonitor
- Ingress

## Template Files

- `templates/deployment.yaml`: service Deployment, container image, env vars,
  probes, resources, volumes, and scheduling settings.
- `templates/serviceaccount.yaml`: optional ServiceAccount.
- `templates/service.yaml`: ClusterIP or LoadBalancer Service.
- `templates/configmap.yaml`: optional ConfigMap from `configMap.data`.
- `templates/externalsecret.yaml`: optional per-service ExternalSecret.
- `templates/hpa.yaml`: optional autoscaling/v2 HorizontalPodAutoscaler.
- `templates/pdb.yaml`: optional PodDisruptionBudget.
- `templates/podmonitor.yaml`: optional Prometheus Operator PodMonitor.
- `templates/ingress.yaml`: optional AWS Load Balancer Controller compatible
  Ingress.
- `templates/_helpers.tpl`: chart naming, labels, service account name, and
  image reference helpers.

Do not add Markdown files under `templates/`; Helm attempts to render every file
in that directory.

## Required Image Values

The chart requires a concrete image repository and tag:

```yaml
image:
  registry: 974263620909.dkr.ecr.us-east-2.amazonaws.com
  repository: petclinic-dev-api-gateway
  tag: "3ec23df"
  pullPolicy: IfNotPresent
```

The final image reference is:

```text
<registry>/<repository>:<tag>
```

If `registry` is empty, the chart renders `<repository>:<tag>`.

## Common Values

| Value | Purpose |
| --- | --- |
| `nameOverride` | Service name used for Kubernetes resources. |
| `environment` | Environment label value such as `dev` or `prod`. |
| `replicaCount` | Static replica count when autoscaling is disabled. |
| `service.port` | Kubernetes Service port. |
| `service.targetPort` | Container port exposed as named port `http`. |
| `env` | Literal environment variables. |
| `secretEnv` | Environment variables sourced from Kubernetes Secrets. |
| `configMapEnv` | Environment variables sourced from ConfigMaps. |
| `externalSecret` | Optional ExternalSecret rendered with the service. |
| `configMap` | Optional ConfigMap rendered with the service. |
| `probes` | Liveness, readiness, and startup probes. |
| `resources` | Container requests and limits. |
| `autoscaling` | HPA settings. |
| `pdb` | PodDisruptionBudget settings. |
| `monitoring.podMonitor` | Prometheus Operator PodMonitor settings. |
| `ingress` | ALB ingress settings. |

## Service Dependencies

Most services use an init container that waits for `config-server` before the
main container starts. Application services also point Eureka clients at
`discovery-server`.

The usual deployment order is:

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

## Monitoring

When `monitoring.podMonitor.enabled = true`, the chart creates a `PodMonitor`
that scrapes:

```text
/actuator/prometheus
```

The environment values add label `release=monitoring`, which matches the
Prometheus selector configured by the Terraform add-ons module.

## Ingress

The chart supports a single `ingress.host`, multiple `ingress.hosts`, and
path-based routing through `ingress.path`. In dev, ingress is enabled for
`api-gateway`, `admin-server`, and `discovery-server`. The chart emits AWS Load
Balancer Controller annotations for:

- scheme
- target type
- listen ports
- SSL redirect
- ALB name
- certificate ARN
- additional custom annotations

## Local Render

```bash
helm template customers-service helm/petclinic-service \
  --namespace petclinic-dev \
  -f helm-values/dev.yaml \
  -f helm-values/customers-service.yaml
```
