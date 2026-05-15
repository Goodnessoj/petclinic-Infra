locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.terraform_state_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  name_prefix                           = var.project_name
  github_repositories                   = var.github_repositories
  repository_prefix                     = var.repository_prefix
  role_name                             = var.github_actions_role_name
  terraform_state_bucket_name           = aws_s3_bucket.terraform_state.bucket
  terraform_state_key_prefix            = var.platform_state_key_prefix
  terraform_state_kms_key_arn           = var.terraform_state_kms_key_arn
  enable_platform_terraform_permissions = true
  tags                                  = local.common_tags
}
