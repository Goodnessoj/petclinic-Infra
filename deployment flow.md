# Deployment Flow

This document explains how this repository builds, deploys, exposes, monitors,
and safely tears down the Spring Petclinic platform.

## Big Picture

This repository is the infrastructure and GitOps source of truth for running the
Spring Petclinic microservices platform on AWS EKS.

The normal flow is:

```text
GitHub Actions
  -> Terraform
  -> AWS platform resources
  -> EKS platform add-ons
  -> shared runtime secrets
  -> Argo CD Applications
  -> Helm-rendered Petclinic services
  -> ALB / Route 53 / ACM public endpoints
  -> Prometheus, Grafana, Loki, Fluent Bit, Zipkin, Alertmanager
```

The important directories are:

| Path | Responsibility |
| --- | --- |
| `.github/workflows` | Automation for Terraform, Argo CD, image tag updates, and direct Helm deployment. |
| `terraform/environments` | Root Terraform stacks for bootstrap, dev, and prod. |
| `terraform/modules` | Reusable modules for VPC, EKS, ECR, RDS, secrets, DNS, observability, and add-ons. |
| `helm/petclinic-service` | Generic Helm chart used once per Petclinic service. |
| `helm/petclinic-secrets` | Shared ExternalSecret resources for database and OpenAI-style runtime secrets. |
| `helm-values` | Environment defaults, service settings, image tags, and secret source names. |
| `k8s/argocd/applications` | Argo CD AppProject and one Application per service. |
| `k8s/base` and `k8s/overlays` | Older raw Kubernetes/Kustomize reference manifests. The active path is Helm through Argo CD. |

## 1. Bootstrap Layer

The durable bootstrap layer is `terraform/environments/bootstrap`.

It creates the resources that should survive normal environment rebuilds:

- S3 remote state bucket: `petclinic-tfstate-974263620909`.
- Backend state key: `petclinic/bootstrap/terraform.tfstate`.
- GitHub Actions OIDC provider for `token.actions.githubusercontent.com`.
- IAM role: `petclinic-github-actions-role`.
- IAM policies that let GitHub Actions push ECR images, read/write Terraform
  state, manage platform AWS resources, and update selected runtime secrets.

The bootstrap S3 bucket has versioning, AES256 encryption, public access
blocking, ownership controls, a deletion guardrail policy, and
`prevent_destroy`.

Do not destroy this root during routine dev/prod rebuilds. If the state bucket
is removed, the platform roots cannot safely persist Terraform state.

## 2. Environment Platform Layer

The deployable environment roots are:

- `terraform/environments/dev`
- `terraform/environments/prod`

Both roots use the same module pattern:

```text
vpc -> ecr -> observability -> eks -> rds -> secrets -> dns-ingress -> addons
```

The environment roots create:

- VPC, public subnets, internet gateway, route table, and security groups.
- ECR repositories for the eight services.
- CloudWatch log groups and a CloudWatch dashboard.
- EKS cluster, managed node group, EKS add-ons, OIDC provider, and IRSA roles.
- RDS MySQL database and generated database secret.
- Optional non-database Secrets Manager entries such as Grafana and OpenAI.
- ACM certificates and Route 53 validation records.
- Kubernetes add-ons inside EKS.

Dev defaults use:

- Cluster name: `petclinic-dev-eks`
- Namespace: `petclinic-dev`
- VPC CIDR: `10.0.0.0/16`
- ECR repository prefix: `petclinic-dev`
- RDS class: `db.t3.micro`
- RDS deletion protection: disabled

Prod defaults use:

- Cluster name: `petclinic-prod-eks`
- Namespace: `petclinic-prod`
- VPC CIDR: `10.1.0.0/16`
- ECR repository prefix: `petclinic-prod`
- RDS class: `db.t3.small`
- RDS Multi-AZ: enabled
- RDS deletion protection: enabled
- RDS final snapshot: enabled

## 3. EKS And Platform Add-ons

The EKS module creates:

- EKS control plane.
- Managed node group.
- EKS OIDC provider.
- EKS add-ons: VPC CNI, kube-proxy, CoreDNS, and AWS EBS CSI driver.
- IRSA role for External Secrets Operator.
- IRSA role for AWS Load Balancer Controller.
- IRSA role for EBS CSI.
- EKS access entries for the GitHub Actions role and optional admin roles.

The add-ons module then installs the runtime platform:

- `external-secrets` namespace and External Secrets Operator.
- `ClusterSecretStore/aws-secrets-manager`.
- Application namespace: `petclinic-<env>`.
- AWS Load Balancer Controller in `kube-system`.
- Optional ExternalDNS in `kube-system`.
- Argo CD in `argocd`.
- kube-prometheus-stack in `monitoring`.
- Grafana, Prometheus, and Alertmanager service aliases.
- Loki deployment and service.
- Fluent Bit DaemonSet for log shipping into Loki.
- Zipkin in `tracing`.
- Petclinic Grafana datasource and dashboard ConfigMaps.
- Petclinic Prometheus alert rules.
- Optional Argo CD repository credentials secret.

## 4. RDS And Secret Handling

### RDS Database Secret

The RDS module creates a MySQL 8.0 instance and generates a random 32-character
database password.

It stores the connection data in AWS Secrets Manager:

```text
petclinic/<environment>/terraform/database
```

The JSON secret contains:

```text
username
password
host
port
dbname
MYSQL_HOST
MYSQL_USER
MYSQL_PASSWORD
MYSQL_DATABASE
```

Network access is restricted with security group rules that allow MySQL
traffic on port `3306` from the EKS cluster and EKS node security groups.

### External Secrets Bridge

Terraform installs External Secrets Operator and creates this cluster-wide
secret store:

```text
ClusterSecretStore/aws-secrets-manager
```

That store authenticates to AWS Secrets Manager through the
`external-secrets` service account and its IRSA role.

The shared Helm chart `helm/petclinic-secrets` creates:

| ExternalSecret | Kubernetes Secret | Remote AWS secret |
| --- | --- | --- |
| `petclinic-db-secret` | `mysql-secret` | `petclinic/dev/terraform/database` or `petclinic/prod/terraform/database` |
| `petclinic-openai-secret` | `openai-secret` | `petclinic/<env>/terraform/openai-api-key` when enabled |

The database mapping copies:

- `MYSQL_PASSWORD`
- `MYSQL_USER`
- `MYSQL_HOST`
- `MYSQL_DATABASE`

The workflows wait for `mysql-secret` before deploying application workloads.

### OpenAI Secret

The repository supports two OpenAI secret patterns:

1. Terraform can create a Secrets Manager secret named
   `petclinic/<env>/terraform/openai-api-key` when
   `create_openai_secret = true`.
2. The current GitHub Actions workflows create the Kubernetes `openai-secret`
   directly from the `OPENAI_API_KEY` GitHub secret.

The active workflow path uses option 2 and installs the shared secrets chart
with:

```text
--set openai.enabled=false
```

That avoids putting the OpenAI key into Terraform-managed secret versions and
Terraform state. `genai-service` reads the Kubernetes secret key
`SPRING_AI_OPENAI_API_KEY`.

## 5. Helm Packaging

The active application deployment path uses the chart:

```text
helm/petclinic-service
```

The chart can render:

- Deployment
- ServiceAccount
- Service
- ConfigMap
- ExternalSecret
- HorizontalPodAutoscaler
- PodDisruptionBudget
- PodMonitor
- Ingress

Argo CD renders the chart once per service.

Values are merged in this order:

```text
helm-values/<environment>.yaml
helm-values/<service>.yaml
```

Later files win, so service values override environment defaults.

Environment values provide shared defaults such as image registry,
repository prefix, resources, PDB settings, PodMonitor labels, and ingress
defaults.

Service values provide service-specific names, ports, image tags, environment
variables, ingress hosts, init containers, and monitoring enablement.

Current services:

| Service | Port | Purpose |
| --- | ---: | --- |
| `config-server` | 8888 | Reads config from the Spring Petclinic config repo. |
| `discovery-server` | 8761 | Eureka service discovery. |
| `customers-service` | 8081 | Customer domain service. |
| `visits-service` | 8082 | Visit domain service. |
| `vets-service` | 8083 | Vet domain service. |
| `genai-service` | 8084 | GenAI service that uses `openai-secret`. |
| `api-gateway` | 8080 behind service port 80 | Public edge service. |
| `admin-server` | 9090 | Admin UI/service. |

Most services use an init container that waits for `config-server`. Application
services also point Eureka clients to `discovery-server`.

## 6. Argo CD GitOps Flow

Terraform installs Argo CD through the add-ons module with the `argo-cd` Helm
chart. The `deploy-argocd.yml` workflow can also install or upgrade the same
release and apply the app manifests.

Argo CD configuration lives under:

```text
k8s/argocd/applications
```

It contains:

- `project.yaml`: AppProject named `petclinic`.
- `dev/`: dev Applications.
- `prod/`: prod Applications.

The AppProject allows source repo:

```text
https://github.com/Goodnessoj/petclinic-Infra.git
```

and destinations:

```text
petclinic-dev
petclinic-prod
```

There is one Argo CD Application per service. Each Application points at:

```text
path: helm/petclinic-service
targetRevision: main
```

and uses two value files:

```text
../../helm-values/<environment>.yaml
../../helm-values/<service>.yaml
```

### Sync Waves

Argo CD sync waves encode the dependency order:

| Wave | Services |
| ---: | --- |
| `0` | `config-server` |
| `1` | `discovery-server` |
| `2` | `customers-service`, `vets-service`, `visits-service`, `genai-service` |
| `3` | `api-gateway`, `admin-server` |

Dev Applications have automated sync:

```text
prune: true
selfHeal: true
```

Prod Applications do not enable automated sync, so production promotion is
manual.

Common sync options are:

```text
CreateNamespace=true
ApplyOutOfSyncOnly=true
PruneLast=true
```

## 7. GitHub Actions Pipeline

### Platform Workflow

File:

```text
.github/workflows/platform.yaml
```

Purpose:

- Run Terraform `plan`, `apply`, or `destroy` for `dev` or `prod`.
- On pull request and push events, run plan-oriented validation only.
- On manual dispatch, allow `plan`, `apply`, or `destroy`.
- Optionally bootstrap GitOps after apply.

High-level apply flow:

```text
checkout
setup Terraform / kubectl / Helm
assume AWS role through GitHub OIDC
terraform fmt
terraform init
remove legacy aws-auth state binding if present
ensure workflow role has EKS access if cluster exists
terraform validate
terraform plan
terraform apply
read Terraform outputs
update kubeconfig
create application namespace
validate External Secrets prerequisites
create openai-secret from GitHub secret
install petclinic-secrets chart with openai.enabled=false
wait for mysql-secret
apply Argo CD AppProject and Applications
hard refresh each Application
wait for Applications to become Synced and Healthy
```

High-level destroy flow:

```text
terraform plan -destroy
export cluster, namespace, VPC, and certificate context
update kubeconfig if the cluster still exists
delete Argo CD Applications
delete ExternalSecrets and stale finalizers
delete application, Argo CD, monitoring, and tracing ingresses
delete TargetGroupBindings and stale finalizers
destroy Terraform-managed platform ingress/DNS resources first
optionally force-delete leftover cluster ALBs
wait for ACM certificates to detach from ALB listeners
run terraform destroy
if destroy fails and force cleanup is enabled, clean VPC dependencies and retry
```

The VPC dependency cleanup script can remove leftover ELBv2/classic load
balancers, target groups, VPC endpoints, ENIs, subnets, route
tables, network ACLs, security groups, and internet gateways for the target VPC.

### Deploy Argo CD Workflow

File:

```text
.github/workflows/deploy-argocd.yml
```

Triggers:

- Pushes that change `k8s/argocd/**`.
- `repository_dispatch` event type `deploy-argocd`.
- Manual dispatch.

Flow:

```text
checkout
setup kubectl and Helm
assume AWS role
resolve env, cluster, namespace, secret values file, and services
ensure workflow role has EKS cluster-admin access
update kubeconfig
install or upgrade Argo CD Helm release
configure Argo CD RBAC
wait for Argo CD workloads
create app namespace
validate External Secrets prerequisites
create openai-secret from GitHub secret
install petclinic-secrets chart with openai.enabled=false
wait for mysql-secret
apply AppProject and environment Applications
hard refresh selected Applications
optionally wait for selected Applications to be Synced and Healthy
```

The workflow can refresh all services or only services sent in the dispatch
payload.

### Update Image Tags Workflow

File:

```text
.github/workflows/update-image-tags.yml
```

Trigger:

```text
repository_dispatch: app-image-built
```

This is the GitOps bridge from the application build pipeline into this infra
repo.

Expected payload includes:

- `sha`: image tag to deploy.
- `services`: service names to update.
- optional `environment`, defaulting to `dev`.

Flow:

```text
checkout main
configure git identity
for each service:
  edit helm-values/<service>.yaml
  replace image.tag with payload sha
commit and push the changed helm-values files
trigger deploy-argocd repository_dispatch
```

Because dev Argo CD Applications auto-sync, committed image tag changes are
enough for dev rollout. The follow-up dispatch forces Argo CD to refresh and
wait for the affected apps.

### Direct Helm Deployment Workflow

File:

```text
.github/workflows/deploy-services.yaml
```

This is an imperative fallback path for selected services. It is useful when
recovering GitOps or when a direct Helm deployment is intentionally needed.

Flow:

```text
checkout main
setup kubectl and Helm
install jq
assume AWS role
update kubeconfig
resolve requested services in dependency order
validate External Secrets prerequisites
recover broken petclinic-secrets Helm release if needed
install petclinic-secrets with openai.enabled=false
create openai-secret from GitHub secret
wait for mysql-secret
helm upgrade --install each service in dependency order
wait for api-gateway public endpoint when api-gateway is deployed
print Helm, pod, service, and ingress summary
```

Dependency order:

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

## 8. Monitoring And Observability

Monitoring is split between AWS-side resources and in-cluster observability.

### AWS-side Observability

The Terraform `observability` module creates:

- CloudWatch log group for the EKS cluster:
  `/aws/eks/petclinic-<env>/cluster`
- CloudWatch log group for each service:
  `/aws/eks/petclinic-<env>/application/<service>`
- CloudWatch dashboard:
  `PetClinic-<env>`

The dashboard includes EKS cluster status and RDS database connection widgets.

### In-cluster Metrics

The add-ons module installs kube-prometheus-stack into:

```text
monitoring
```

Prometheus is configured to discover `PodMonitor` resources with:

```text
release=monitoring
```

The service chart creates a PodMonitor when:

```text
monitoring.podMonitor.enabled: true
```

All service values enable PodMonitor scraping at:

```text
/actuator/prometheus
```

The service values also enable Spring HTTP percentile histogram metrics with:

```text
MANAGEMENT_METRICS_DISTRIBUTION_PERCENTILESHISTOGRAM_HTTP_SERVER_REQUESTS=true
```

### Grafana

Grafana is installed by kube-prometheus-stack. Terraform adds:

- A service alias named `grafana`.
- Datasource ConfigMap for Prometheus and Loki.
- Petclinic dashboard ConfigMap.
- Optional ALB ingress and Route 53 record.

The Petclinic dashboard includes panels for:

- HTTP request rate.
- HTTP 5xx rate.
- P99 response time.
- Memory usage.
- Pod restarts.
- Application logs from Loki.

### Logs

Loki runs as a lightweight deployment in the `monitoring` namespace.

Fluent Bit runs as a DaemonSet and tails:

```text
/var/log/containers/*.log
```

It enriches records with Kubernetes metadata and sends them to Loki on port
`3100`. Grafana reads logs from the Loki datasource.

### Tracing

Zipkin runs in:

```text
tracing
```

Service values point Spring tracing to:

```text
http://zipkin.tracing:9411/api/v2/spans
```

and set:

```text
MANAGEMENT_TRACING_SAMPLING_PROBABILITY=1.0
```

When platform ingress is enabled, Zipkin is exposed through the configured
Zipkin hostname.

### Alerting

Terraform creates a `PrometheusRule` named:

```text
petclinic-alert-rules
```

The managed alerts are:

| Alert | Meaning |
| --- | --- |
| `PetclinicHighErrorRate` | HTTP 5xx ratio above 5% for 5 minutes. |
| `PetclinicPodRestartLoop` | More than 5 restarts in 15 minutes. |
| `PetclinicHighMemoryUsage` | Container memory above 80% of its memory limit. |
| `PetclinicServiceDown` | No successful Prometheus scrape for 2 minutes. |
| `PetclinicSlowP99ResponseTime` | P99 latency above 2 seconds for 5 minutes. |

Alertmanager groups Petclinic alerts under the `petclinic-alerts` receiver.
The current receiver is visible in Alertmanager but does not send to Slack,
email, PagerDuty, or a webhook until one is added.

## 9. DNS, Ingress, And Public Access

When `enable_dns_ingress = true`, Terraform creates ACM certificates and DNS
validation records in Route 53.

The `dns-ingress` module creates:

- ACM certificate for the app hostname.
- Subject alternative names for platform and selected service hostnames.
- Route 53 validation records.
- ACM certificate validation.

The add-ons module creates platform ingresses and Route 53 CNAME records for:

- Argo CD
- Grafana
- Prometheus
- Zipkin

The service Helm chart creates AWS Load Balancer Controller compatible Ingress
objects for services that enable ingress.

The chart emits annotations for:

- ALB scheme.
- ALB target type.
- HTTP/HTTPS listener ports.
- SSL redirect.
- Optional ALB name.
- Optional ACM certificate ARN.
- Optional custom annotations.

Current dev endpoints are:

```text
https://petclinic.phoniex.site
https://petclinic.phoniex.site/admin
https://eureka.phoniex.site
https://discovery.phoniex.site
https://argocd.phoniex.site
https://grafana.phoniex.site
https://prometheus.phoniex.site
https://zipkin.phoniex.site
```

## 10. End-to-end Deployment Scenarios

### Initial Platform Creation

```text
1. Apply terraform/environments/bootstrap.
2. Run the Platform workflow for dev or prod with action=apply.
3. Terraform creates AWS infrastructure and EKS add-ons.
4. The workflow creates runtime Kubernetes secrets.
5. The workflow installs the shared secrets chart.
6. External Secrets creates mysql-secret from AWS Secrets Manager.
7. The workflow applies Argo CD AppProject and Applications.
8. Argo CD renders Helm releases for all services.
9. AWS Load Balancer Controller creates ALBs for enabled ingresses.
10. Route 53 records point public hostnames to ALB hostnames.
11. Prometheus, Grafana, Loki, Fluent Bit, Zipkin, and Alertmanager observe the platform.
```

### Application Image Update

```text
1. Application CI builds and pushes one or more service images to ECR.
2. Application CI sends repository_dispatch app-image-built to this repo.
3. update-image-tags.yml edits helm-values/<service>.yaml image.tag.
4. The workflow commits and pushes the tag update to main.
5. It dispatches deploy-argocd with the changed services.
6. deploy-argocd refreshes those Argo CD Applications.
7. Dev auto-syncs, prunes drift, and self-heals.
```

### Direct Service Recovery

```text
1. Manually run Deploy Changed Petclinic Services.
2. Select dev or prod and the service list, or use all.
3. The workflow validates External Secrets and ClusterSecretStore.
4. It ensures mysql-secret and openai-secret exist.
5. It runs helm upgrade --install in dependency order.
6. It prints release, pod, service, and ingress status.
```

### Safe Teardown And Rebuild

```text
1. Run the Platform workflow with action=destroy.
2. The workflow deletes GitOps Applications and Kubernetes resources that own AWS load balancers.
3. It removes stale finalizers on ExternalSecrets, ingresses, and TargetGroupBindings.
4. It destroys Terraform-managed platform ingress and DNS records first.
5. It waits for ACM certificates to detach from ALB listeners.
6. It runs terraform destroy.
7. If needed, it force-cleans VPC dependencies and retries destroy.
8. Bootstrap state resources remain intact.
9. Re-run Platform action=apply to recreate the environment.
```

## 11. Useful Verification Commands

Update kubeconfig:

```bash
aws eks update-kubeconfig --region us-east-2 --name petclinic-dev-eks
```

Check platform add-ons:

```bash
kubectl get pods -n external-secrets
kubectl get clustersecretstore aws-secrets-manager
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl get pods -n argocd
kubectl get pods -n monitoring
kubectl get pods -n tracing
```

Check secrets:

```bash
kubectl get externalsecret -n petclinic-dev
kubectl get secret mysql-secret -n petclinic-dev
kubectl get secret openai-secret -n petclinic-dev
```

Check Argo CD:

```bash
kubectl get applications -n argocd -o wide
```

Check workloads:

```bash
kubectl get pods,svc,ingress -n petclinic-dev
```

Check monitoring rules and alerts:

```bash
kubectl get prometheusrule -n monitoring petclinic-alert-rules
kubectl get --raw /api/v1/namespaces/monitoring/services/http:prometheus:9090/proxy/api/v1/rules
kubectl get --raw /api/v1/namespaces/monitoring/services/http:alertmanager:9093/proxy/api/v2/status
kubectl get --raw /api/v1/namespaces/monitoring/services/http:alertmanager:9093/proxy/api/v2/alerts
```

Render a service locally:

```bash
helm template api-gateway helm/petclinic-service \
  --namespace petclinic-dev \
  -f helm-values/dev.yaml \
  -f helm-values/api-gateway.yaml
```

Render shared secrets locally:

```bash
helm template petclinic-secrets helm/petclinic-secrets \
  --namespace petclinic-dev \
  -f helm-values/secrets-dev.yaml \
  --set openai.enabled=false
```

## 12. Safety Notes

- Keep `terraform/environments/bootstrap` alive during normal rebuilds.
- Keep credentials out of committed values files.
- Terraform state can contain sensitive values. Do not commit state files.
- If Terraform writes `errored.tfstate`, restore the backend first, then push
  the recovered state with `terraform state push errored.tfstate`.
- The ECR module uses `force_delete = true`, so destroying an environment can
  delete service images in those repositories.
- The active deployment path is Argo CD plus Helm. Do not apply the raw
  Kustomize overlays to the same namespaces while Argo CD manages the Helm
  releases.
- Prod Applications are manual sync by design. Review image tags, ingress
  settings, capacity, DNS, and secret handling before promoting production.
