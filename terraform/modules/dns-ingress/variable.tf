variable "environment" {
  description = "Environment name"
  type        = string
}

variable "root_domain_name" {
  description = "Root domain name hosted in Route 53, for example phoniex.site"
  type        = string
}

variable "app_subdomain" {
  description = "Subdomain for the application, for example petclinic"
  type        = string
  default     = "petclinic"
}

variable "additional_subdomains" {
  description = "Additional subdomains to include on the ACM certificate."
  type        = list(string)
  default     = []
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS cluster CA certificate base64 encoded"
  type        = string
  sensitive   = true
}

variable "lb_controller_service_account" {
  description = "Service account name for Load Balancer Controller"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
