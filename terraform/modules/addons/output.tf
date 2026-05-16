output "external_secrets_role_arn" {
  description = "IRSA role ARN used by External Secrets Operator."
  value       = var.external_secrets_role_arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "IRSA role ARN used by AWS Load Balancer Controller."
  value       = var.aws_load_balancer_controller_role_arn
}

output "external_dns_role_arn" {
  description = "IRSA role ARN used by ExternalDNS."
  value       = var.enable_platform_ingress ? aws_iam_role.external_dns[0].arn : null
}

output "monitoring_namespace" {
  description = "Namespace where kube-prometheus-stack is installed."
  value       = helm_release.monitoring.namespace
}

output "argocd_namespace" {
  description = "Namespace where Argo CD is installed."
  value       = helm_release.argocd.namespace
}

output "argocd_hostname" {
  description = "External ArgoCD hostname."
  value       = var.enable_platform_ingress ? var.argocd_hostname : null
}

output "grafana_hostname" {
  description = "External Grafana hostname."
  value       = var.enable_platform_ingress ? var.grafana_hostname : null
}

output "prometheus_hostname" {
  description = "External Prometheus hostname."
  value       = var.enable_platform_ingress ? var.prometheus_hostname : null
}

output "application_namespace" {
  description = "Namespace where the Petclinic application is deployed."
  value       = kubernetes_namespace_v1.application.metadata[0].name
}
