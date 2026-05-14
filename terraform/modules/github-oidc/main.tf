data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  repository_prefix = trimsuffix(var.repository_prefix, "-")

  github_subjects = distinct(flatten([
    for repo in var.github_repositories : concat(
      [
        for branch in repo.branches :
        "repo:${repo.owner}/${repo.name}:ref:refs/heads/${branch}"
      ],
      [
        for environment in repo.environments :
        "repo:${repo.owner}/${repo.name}:environment:${environment}"
      ]
    )
  ]))

  role_name = coalesce(var.role_name, "${var.name_prefix}-github-actions")
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_subjects
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "github_ecr_push" {
  statement {
    sid    = "ReadCallerIdentity"
    effect = "Allow"

    actions = [
      "sts:GetCallerIdentity"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AuthenticateToEcr"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "PushAndPullPrefixedImages"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${local.repository_prefix}-*"
    ]
  }

  statement {
    sid    = "DescribeEksClusters"
    effect = "Allow"

    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_ecr_push" {
  name        = "${var.name_prefix}-github-ecr-push-policy"
  description = "Allow GitHub Actions to push Docker images to ECR"
  policy      = data.aws_iam_policy_document.github_ecr_push.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "github_ecr_push" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_ecr_push.arn
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}
