variable "project_name" {
  description = "Project identifier used for naming."
  type        = string
}

variable "environment" {
  description = "Environment name (for example dev or prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region used in CloudWatch dashboard widgets."
  type        = string
}

variable "enable_container_insights" {
  description = "Whether to enable container insights integrations."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Default retention period for logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to resources in this module."
  type        = map(string)
  default     = {}
}
