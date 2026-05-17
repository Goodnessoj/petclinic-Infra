variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by AWS Load Balancer Controller."
  type        = string
}

variable "environment" {
  description = "Environment label value."
  type        = string
}

variable "application_namespace" {
  description = "Namespace where the Petclinic application is deployed."
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA."
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider URL without the https:// prefix."
  type        = string
}

variable "secrets_manager_secret_arns" {
  description = "Secrets Manager secret ARNs that External Secrets may read."
  type        = list(string)
  default     = []
}

variable "external_secrets_role_arn" {
  description = "Existing IRSA role ARN used by External Secrets Operator."
  type        = string
}

variable "aws_load_balancer_controller_role_arn" {
  description = "Existing IRSA role ARN used by AWS Load Balancer Controller."
  type        = string
}

variable "external_secrets_chart_version" {
  description = "Optional pinned External Secrets Helm chart version."
  type        = string
  default     = "2.5.0"
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Optional pinned AWS Load Balancer Controller Helm chart version."
  type        = string
  default     = "3.3.0"
}

variable "external_dns_chart_version" {
  description = "Optional pinned ExternalDNS Helm chart version."
  type        = string
  default     = "1.21.1"
}

variable "kube_prometheus_stack_chart_version" {
  description = "Pinned kube-prometheus-stack Helm chart version."
  type        = string
  default     = "85.1.2"
}

variable "argocd_chart_version" {
  description = "Optional pinned Argo CD Helm chart version."
  type        = string
  default     = "9.5.14"
}

variable "grafana_service_type" {
  description = "Grafana Kubernetes service type."
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "LoadBalancer"], var.grafana_service_type)
    error_message = "grafana_service_type must be ClusterIP or LoadBalancer."
  }
}

variable "enable_platform_ingress" {
  description = "Whether to expose ArgoCD, Grafana, and Prometheus through ALB ingresses."
  type        = bool
  default     = false
}

variable "root_domain_name" {
  description = "Root domain name hosted in Route 53. Required when enable_platform_ingress is true."
  type        = string
  default     = ""
}

variable "argocd_hostname" {
  description = "External hostname for the ArgoCD UI."
  type        = string
  default     = ""
}

variable "grafana_hostname" {
  description = "External hostname for the Grafana UI."
  type        = string
  default     = ""
}

variable "prometheus_hostname" {
  description = "External hostname for the Prometheus UI."
  type        = string
  default     = ""
}

variable "platform_certificate_arn" {
  description = "ACM certificate ARN used by ArgoCD, Grafana, and Prometheus ALB ingresses."
  type        = string
  default     = ""
}

variable "platform_alb_group_name" {
  description = "AWS Load Balancer Controller ingress group name for platform UIs."
  type        = string
  default     = "petclinic-platform"
}

variable "platform_alb_name" {
  description = "AWS load balancer name for platform UI ingresses."
  type        = string
  default     = "petclinic-platform"
}

variable "argocd_repo_url" {
  description = "Git repository URL Argo CD will read. Used for optional private repo credentials."
  type        = string
  default     = ""
}

variable "argocd_repo_username" {
  description = "Username for optional Argo CD private repo credentials."
  type        = string
  default     = "x-access-token"
}

variable "argocd_repo_token" {
  description = "Token for optional Argo CD private repo credentials."
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
