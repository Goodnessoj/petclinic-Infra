locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  state_bucket_guardrail_exempt_principal_arns = distinct(compact(concat(
    ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"],
    var.state_bucket_guardrail_exempt_principal_arns,
  )))
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

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

data "aws_iam_policy_document" "terraform_state_guardrail" {
  statement {
    sid    = "DenyTerraformStateBucketDeletion"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:DeleteBucket",
      "s3:DeleteBucketPolicy",
      "s3:PutLifecycleConfiguration",
    ]

    resources = [aws_s3_bucket.terraform_state.arn]

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalArn"
      values   = local.state_bucket_guardrail_exempt_principal_arns
    }
  }

  statement {
    sid    = "DenyTerraformStateObjectDeletion"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
    ]

    resources = ["${aws_s3_bucket.terraform_state.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalArn"
      values   = local.state_bucket_guardrail_exempt_principal_arns
    }
  }
}

resource "aws_s3_bucket_policy" "terraform_state_guardrail" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = data.aws_iam_policy_document.terraform_state_guardrail.json
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  name_prefix                           = var.project_name
  github_repositories                   = var.github_repositories
  repository_prefix                     = var.repository_prefix
  role_name                             = var.github_actions_role_name
  terraform_state_bucket_name           = aws_s3_bucket.terraform_state.bucket
  terraform_state_key_prefix            = var.bootstrap_state_key_prefix
  terraform_state_key_prefixes          = [var.platform_state_key_prefix, var.prod_state_key_prefix]
  terraform_state_kms_key_arn           = var.terraform_state_kms_key_arn
  enable_platform_terraform_permissions = true
  tags                                  = local.common_tags
}
