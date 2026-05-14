output "repository_urls" {
  description = "Map of service names to ECR repository URLs"
  value = {
    for service, repo in aws_ecr_repository.service :
    service => repo.repository_url
  }
}

output "repository_names" {
  description = "List of ECR repository names"
  value       = [for repo in aws_ecr_repository.service : repo.name]
}

output "registry_url" {
  description = "ECR registry URL (without service name)"
  value       = split("/", aws_ecr_repository.service["config-server"].repository_url)[0]
}
