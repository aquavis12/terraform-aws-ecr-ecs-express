variable "name" {
  description = "Prefix for IAM role names."
  type        = string
}

variable "partition" {
  description = "AWS partition, used to build managed policy ARNs."
  type        = string
}

variable "task_execution_role_arn" {
  description = "Existing task execution role ARN. When set, the module creates no execution role."
  type        = string
  default     = null
}

variable "infrastructure_role_arn" {
  description = "Existing infrastructure role ARN. When set, the module creates no infrastructure role."
  type        = string
  default     = null
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs the task execution role may pull. Empty = no pull policy."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to created roles."
  type        = map(string)
  default     = {}
}
