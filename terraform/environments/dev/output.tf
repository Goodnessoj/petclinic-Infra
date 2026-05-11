# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.vpc.eks_cluster_security_group_id
}

output "microservices_security_group_id" {
  description = "Microservices security group ID"
  value       = module.vpc.microservices_security_group_id
}

# ============================================
# ECR Outputs
# ============================================
output "ecr_registry_url" {
  description = "ECR registry URL"
  value       = module.ecr.registry_url
}

output "ecr_repository_urls" {
  description = "Map of service names to ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "ecr_repository_names" {
  description = "List of ECR repository names"
  value       = module.ecr.repository_names
}

# ============================================
# RDS Outputs
# ============================================
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
}

output "rds_secret_arn" {
  description = "Secrets Manager secret ARN for database credentials"
  value       = module.rds.db_secret_arn
}

# ============================================
# Secrets Outputs
# ============================================
output "openai_secret_arn" {
  description = "OpenAI API key secret ARN"
  value       = module.secrets.openai_secret_arn
}

output "grafana_secret_arn" {
  description = "Grafana admin secret ARN"
  value       = module.secrets.grafana_secret_arn
}

