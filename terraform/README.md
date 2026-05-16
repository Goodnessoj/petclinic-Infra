# Terraform

This folder contains the Terraform code that provisions the AWS infrastructure
for the Petclinic platform.

## Structure

| Path | Purpose |
| --- | --- |
| [`environments/`](environments/README.md) | Root modules for durable bootstrap infrastructure and deployable environments. |
| [`modules/`](modules/README.md) | Reusable modules for VPC, EKS, ECR, RDS, DNS, secrets, observability, GitHub OIDC, and platform add-ons. |

## Environment Roots

- `environments/bootstrap`: durable foundation for Terraform state and GitHub
  Actions OIDC. Do not destroy this root during routine rebuilds.
- `environments/dev`: active dev platform root.
- `environments/prod`: production platform root with prod-oriented defaults,
  outputs, and a separate remote state key.

## Remote State

The checked-in backends point to S3 keys:

| Environment | State key |
| --- | --- |
| Bootstrap | `petclinic/bootstrap/terraform.tfstate` |
| Dev | `petclinic/dev/terraform.tfstate` |
| Prod | `petclinic/prod/terraform.tfstate` |

The state bucket is created by the bootstrap root and is currently named
`petclinic-tfstate-974263620909`.

## Standard Workflow

Run Terraform from the repository root with `-chdir`:

```bash
terraform -chdir=terraform/environments/dev init
terraform -chdir=terraform/environments/dev fmt -check -recursive
terraform -chdir=terraform/environments/dev validate -no-color
terraform -chdir=terraform/environments/dev plan -var-file=terraform.tfvars
terraform -chdir=terraform/environments/dev apply -var-file=terraform.tfvars
```

`terraform.tfvars` contain's variable  defined in the workflow

## Provider Notes

The dev and prod roots configure:

- `aws` for AWS infrastructure.
- `kubernetes` for cluster resources such as `aws-auth`.
- `helm` for platform add-on charts.
- `random` for generated passwords.
- `tls` for EKS OIDC thumbprint discovery.

The Kubernetes and Helm providers authenticate to the EKS cluster created by the
same root through `aws_eks_cluster_auth`.

## Apply Order

1. Apply `environments/bootstrap`.
2. Apply `environments/dev` or `environments/prod`.
3. Use Terraform outputs to update kubeconfig or let GitHub Actions do it.
4. Bootstrap or refresh Argo CD applications.

The `platform.yaml` workflow automates the dev version of this flow.
