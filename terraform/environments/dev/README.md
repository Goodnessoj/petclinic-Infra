# Dev Environment

This is the active development platform root. It provisions the AWS and
Kubernetes foundation used by the dev Petclinic services.

## What It Manages

- VPC, public subnets, route table, internet gateway, and security groups.
- ECR repositories for all Petclinic services.
- CloudWatch log groups and a CloudWatch dashboard.
- EKS cluster, managed node group, EKS add-ons, and IRSA roles.
- RDS MySQL instance and database credential secret in AWS Secrets Manager.
- OpenAI and Grafana Secrets Manager entries through the `secrets` module.
- Optional Route 53 and ACM resources for app, Argo CD, and Grafana hostnames.
- External Secrets Operator, AWS Load Balancer Controller, optional ExternalDNS,
  Argo CD, kube-prometheus-stack, Grafana, Loki, and related platform services.

## Defaults

Key defaults from `variable.tf`:

- `environment = "dev"`
- `project_name = "petclinic"`
- `aws_region = "us-east-2"`
- `repository_prefix = "petclinic-dev"`
- `cluster_name = "petclinic-dev-eks"`
- `root_domain_name = "phoniex.site"`
- `app_subdomain = "petclinic"`
- `argocd_subdomain = "argocd"`
- `grafana_subdomain = "grafana"`
- EKS desired node count is `3` with `t3.medium` nodes.
- RDS uses `db.t3.micro`, 20 GB gp3 storage, and single-AZ by default.

## Required Local Files

Create `terraform/environments/dev/terraform.tfvars` for shared or local values.
This file is no longer ignored by Git, so commit only sanitized values.
Credentials should stay in GitHub secrets, your shell environment, or another
controlled secret source.

Common overrides:

```hcl
openai_api_key = "..."
eks_admin_role_arns = [
  "arn:aws:iam::<account-id>:role/<admin-role>"
]
```

If GitHub Actions owns the OpenAI runtime secret, keep:

```hcl
create_openai_secret = false
```

## Usage

```bash
terraform -chdir=terraform/environments/dev init
terraform -chdir=terraform/environments/dev fmt -check -recursive
terraform -chdir=terraform/environments/dev validate -no-color
terraform -chdir=terraform/environments/dev plan -var-file=terraform.tfvars
terraform -chdir=terraform/environments/dev apply -var-file=terraform.tfvars
```

Update kubeconfig after apply:

```bash
aws eks update-kubeconfig --region us-east-2 --name petclinic-dev-eks
kubectl get nodes
```

## Important Outputs

- `kubectl_update_kubeconfig_command`
- `eks_cluster_name`
- `ecr_registry_url`
- `ecr_repository_urls`
- `rds_endpoint`
- `rds_secret_name`
- `application_namespace`
- `argocd_domain_name`
- `grafana_domain_name`
- `app_domain_name`

## Post-Apply Checks

```bash
kubectl get ns
kubectl get pods -n argocd
kubectl get pods -n external-secrets
kubectl get pods -n monitoring
kubectl get clustersecretstore aws-secrets-manager
```

If `enable_dns_ingress` is true, Argo CD and Grafana are expected at:

```text
https://argocd.phoniex.site
https://grafana.phoniex.site
```
