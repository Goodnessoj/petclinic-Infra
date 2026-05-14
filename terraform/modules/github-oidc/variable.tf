variable "name_prefix" {
  description = "Name prefix for IAM resources."
  type        = string
}

variable "github_repositories" {
  description = "GitHub repositories allowed to assume the deployment role."
  type = list(object({
    owner        = string
    name         = string
    branches     = optional(list(string), ["main"])
    environments = optional(list(string), [])
  }))

  validation {
    condition     = length(var.github_repositories) > 0
    error_message = "At least one GitHub repository must be allowed."
  }
}

variable "repository_prefix" {
  description = "Plain ECR repository prefix, for example petclinic-dev. Do not include a trailing hyphen."
  type        = string
}

variable "role_name" {
  description = "Optional explicit IAM role name for GitHub Actions."
  type        = string
  default     = null
}

variable "additional_policy_arns" {
  description = "Additional managed policy ARNs to attach to the GitHub Actions role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
