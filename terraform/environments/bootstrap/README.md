# Petclinic Bootstrap

This root owns the durable infrastructure required to run Terraform from
GitHub Actions:

- Terraform state S3 bucket configuration
- GitHub Actions OIDC provider
- `petclinic-github-actions-role`
- GitHub Actions ECR, Terraform state, and platform Terraform IAM policies

Do not destroy this root during normal environment rebuilds. Destroy only the
disposable environment roots, such as `terraform/environments/dev`.

Typical lifecycle:

```bash
terraform -chdir=terraform/environments/bootstrap plan -var-file=terraform.tfvars
terraform -chdir=terraform/environments/dev destroy -var-file=terraform.tfvars
terraform -chdir=terraform/environments/dev apply -var-file=terraform.tfvars
```
