# Add-Ons Module

This module installs Kubernetes platform add-ons into the EKS cluster.

## What It Installs

- Application namespace from the root environment.
- External Secrets Operator.
- `ClusterSecretStore` named `aws-secrets-manager`.
- AWS Load Balancer Controller.
- Optional ExternalDNS.
- Argo CD.
- Optional ALB ingress and Route 53 record for Argo CD.
- kube-prometheus-stack.
- Grafana service alias, optional ALB ingress, and Route 53 record.
- Prometheus service alias.
- Alertmanager service alias.
- Loki deployment and service.
- Fluent Bit log collection into Loki.
- Zipkin deployment and service in the `tracing` namespace.
- Grafana datasource and Petclinic dashboard ConfigMaps.
- Petclinic Prometheus alert rules.
- Optional Argo CD repository credentials secret.

## Required Inputs

Key inputs:

- `cluster_name`
- `aws_region`
- `vpc_id`
- `application_namespace`
- `oidc_provider_arn`
- `oidc_provider_url`
- `external_secrets_role_arn`
- `aws_load_balancer_controller_role_arn`

When platform ingress is enabled:

- `root_domain_name`
- `argocd_hostname`
- `grafana_hostname`
- `platform_certificate_arn`
- `platform_alb_group_name`
- `platform_alb_name`

Optional chart version inputs can pin External Secrets, AWS Load Balancer
Controller, ExternalDNS, kube-prometheus-stack, and Argo CD.

## Namespaces

The module uses these namespaces:

- `external-secrets`
- `kube-system`
- `argocd`
- `monitoring`
- `tracing`
- application namespace from `application_namespace`

## External Secrets

The module installs External Secrets Operator and creates a
`ClusterSecretStore` that reads AWS Secrets Manager in the configured region
using IRSA.

The shared `helm/petclinic-secrets` chart creates application-level
`ExternalSecret` resources that point to this store.

## Monitoring

The module installs kube-prometheus-stack and configures Prometheus selectors so
`PodMonitor` resources with label `release=monitoring` can be discovered in the
application namespace.

It also deploys a lightweight Loki instance and configures Grafana datasources
for Prometheus and Loki. Fluent Bit tails Kubernetes container logs and sends
them to Loki.

The module also deploys Zipkin at `zipkin.tracing:9411`, which matches the
tracing environment variables in the service values files.

## Outputs

- `external_secrets_role_arn`
- `aws_load_balancer_controller_role_arn`
- `external_dns_role_arn`
- `monitoring_namespace`
- `argocd_namespace`
- `argocd_hostname`
- `grafana_hostname`
- `application_namespace`

## Verification

```bash
kubectl get pods -n external-secrets
kubectl get clustersecretstore aws-secrets-manager
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl get pods -n argocd
kubectl get pods -n monitoring
```
