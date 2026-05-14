locals {
  repository_prefix = trimsuffix(var.repository_prefix, "-")

  service_names = [
    "config-server",
    "discovery-server",
    "api-gateway",
    "customers-service",
    "vets-service",
    "visits-service",
    "admin-server",
    "genai-service"
  ]
}

# ECR Repository for each microservice
resource "aws_ecr_repository" "service" {
  for_each = toset(local.service_names)

  name                 = "${local.repository_prefix}-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Environment = var.environment
    Service     = each.key
  })
}

# Lifecycle policy for each repository
resource "aws_ecr_lifecycle_policy" "service" {
  for_each = toset(local.service_names)

  repository = aws_ecr_repository.service[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
