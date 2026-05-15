output "terraform_state_bucket_name" {
  description = "S3 bucket used by Terraform remote state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN."
  value       = module.github_oidc.oidc_provider_arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN assumed by GitHub Actions."
  value       = module.github_oidc.github_actions_role_arn
}

output "github_actions_role_name" {
  description = "IAM role name assumed by GitHub Actions."
  value       = module.github_oidc.github_actions_role_name
}

output "github_actions_allowed_subjects" {
  description = "GitHub OIDC subjects allowed by the trust policy."
  value       = module.github_oidc.allowed_subjects
}
