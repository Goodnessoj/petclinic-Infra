variable "environment" {
  description = "Environment name"
  type        = string
}

variable "repository_prefix" {
  description = "Plain ECR repository prefix, for example petclinic-dev. Do not include a trailing hyphen."
  type        = string
}

variable "tags" {
  description = "Tags applied to repositories."
  type        = map(string)
  default     = {}
}
