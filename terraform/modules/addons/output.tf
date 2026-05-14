output "external_secrets_role_arn" {
  description = "IRSA role ARN used by External Secrets Operator."
  value       = var.external_secrets_role_arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "IRSA role ARN used by AWS Load Balancer Controller."
  value       = var.aws_load_balancer_controller_role_arn
}

output "monitoring_namespace" {
  description = "Namespace where kube-prometheus-stack is installed."
  value       = helm_release.monitoring.namespace
}

output "argocd_namespace" {
  description = "Namespace where Argo CD is installed."
  value       = helm_release.argocd.namespace
}

output "application_namespace" {
  description = "Namespace where the Petclinic application is deployed."
  value       = kubernetes_namespace_v1.application.metadata[0].name
}
