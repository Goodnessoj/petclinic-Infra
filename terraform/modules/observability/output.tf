output "log_retention_days" {
  description = "Log retention value provided to the module."
  value       = var.log_retention_days
}

output "log_group_names" {
  description = "Map of CloudWatch log group names"
  value = {
    for service, log_group in aws_cloudwatch_log_group.application :
    service => log_group.name
  }
}

output "cluster_log_group_name" {
  description = "EKS cluster log group name"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}