variable "name" {
  description = "Prefix for the cluster and service names."
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster to run services in. The cluster is created here when create_cluster is true."
  type        = string
}

variable "create_cluster" {
  description = "Create the ECS cluster. False when an existing cluster name was supplied."
  type        = bool
  default     = true
}

variable "execution_role_arn" {
  description = "Task execution role ARN used by every service."
  type        = string
}

variable "infrastructure_role_arn" {
  description = "Infrastructure role ARN used by Express Mode to manage ALB, scaling, and networking."
  type        = string
}

variable "service_images" {
  description = "Fully-qualified container image reference (repo:tag) keyed by service name."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}

variable "services" {
  description = <<-EOT
    ECS Express Mode services to deploy, keyed by short name.
    See the root module variable of the same name for field documentation.
  EOT
  type = map(object({
    repository            = string
    image_tag             = optional(string, "latest")
    container_port        = optional(number, 80)
    cpu                   = optional(number, 1024)
    memory                = optional(number, 2048)
    health_check_path     = optional(string, "/health")
    public                = optional(bool, true)
    wait_for_steady_state = optional(bool, false)
    task_role_arn         = optional(string)
    subnet_ids            = optional(list(string), [])
    security_group_ids    = optional(list(string), [])

    scaling = optional(object({
      metric       = optional(string, "REQUEST_COUNT_PER_TARGET")
      target_value = optional(number, 60)
      min_tasks    = optional(number, 1)
      max_tasks    = optional(number, 20)
    }), {})

    environment = optional(list(object({
      name  = string
      value = string
    })), [])

    secrets = optional(list(object({
      name       = string
      value_from = string
    })), [])

    log_group = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
