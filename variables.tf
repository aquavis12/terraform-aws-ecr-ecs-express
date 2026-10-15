variable "name" {
  description = "Module name prefix. Used for ECR repos, IAM roles and ECS services."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,32}$", var.name))
    error_message = "name must be 1-32 lowercase letters, digits or hyphens."
  }
}

# ================================================================= ECR

variable "repositories" {
  description = <<-EOT
    ECR private repositories to create.
    name: repository name (appended to var.name as <name>/<repo>).
    image_tag_mutability: MUTABLE or IMMUTABLE.
    force_delete: allow destroy when images exist.
    lifecycle_rules: list of lifecycle policy rules in priority order.
    kms_key_arn: customer-managed key; null = AES256.
  EOT
  type = map(object({
    image_tag_mutability = optional(string, "IMMUTABLE")
    force_delete         = optional(bool, false)
    kms_key_arn          = optional(string)
    lifecycle_rules = optional(list(object({
      description  = optional(string, "")
      tag_status   = optional(string, "any")
      tag_prefix   = optional(string)
      count_type   = string # imageCountMoreThan | sinceImagePushed
      count_number = number
      count_unit   = optional(string) # days — only for sinceImagePushed
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.repositories) : contains(["MUTABLE", "IMMUTABLE"], r.image_tag_mutability)])
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

# ----------------------------------------------------------------- ECR scanning

variable "scan_type" {
  description = "Registry-level scanning type: BASIC (on push, free) or ENHANCED (Inspector V2, per image/month)."
  type        = string
  default     = "ENHANCED"

  validation {
    condition     = contains(["BASIC", "ENHANCED"], var.scan_type)
    error_message = "scan_type must be BASIC or ENHANCED."
  }
}

variable "scan_rules" {
  description = <<-EOT
    Enhanced scanning rules. Each rule has a filter (repo name wildcard) and frequency.
    Frequency: SCAN_ON_PUSH | CONTINUOUS_SCAN | MANUAL.
    Ignored when scan_type = BASIC.
  EOT
  type = list(object({
    filter    = string
    frequency = string
  }))
  default = [{ filter = "*", frequency = "CONTINUOUS_SCAN" }]

  validation {
    condition     = alltrue([for r in var.scan_rules : contains(["SCAN_ON_PUSH", "CONTINUOUS_SCAN", "MANUAL"], r.frequency)])
    error_message = "scan frequency must be SCAN_ON_PUSH, CONTINUOUS_SCAN, or MANUAL."
  }
}

# ----------------------------------------------------------------- ECR cross-region replication

variable "replication_destinations" {
  description = <<-EOT
    Cross-region (and cross-account) replication destinations.
    account_id: target account (omit or set to local account for same-account cross-region).
    regions: list of destination regions.
    prefix_filters: optional list of repo name prefixes to replicate (empty = all).
  EOT
  type = list(object({
    account_id     = optional(string)
    regions        = list(string)
    prefix_filters = optional(list(string), [])
  }))
  default = []
}

# ----------------------------------------------------------------- ECR pull-through cache

variable "pull_through_cache_rules" {
  description = <<-EOT
    Pull-through cache rules for upstream registries.
    ecr_repository_prefix: prefix under which cached images land.
    upstream_registry_url: e.g. public.ecr.aws, registry-1.docker.io, gcr.io.
    credential_arn: Secrets Manager secret ARN with registry credentials (not needed for public.ecr.aws).
  EOT
  type = list(object({
    ecr_repository_prefix = string
    upstream_registry_url = string
    credential_arn        = optional(string)
  }))
  default = []
}

# ----------------------------------------------------------------- ECR registry policy

variable "registry_policy" {
  description = "JSON registry policy for cross-account pull access. Null = no policy."
  type        = string
  default     = null
}

# ================================================================= ECS Express services

variable "ecs_cluster_name" {
  description = "ECS cluster name. Leave null to create a new cluster."
  type        = string
  default     = null
}

variable "services" {
  description = <<-EOT
    ECS Express Mode services to deploy.
    repository: key from var.repositories — the image source.
    image_tag: tag to deploy (e.g. latest, v1.2.3).
    container_port: port the container listens on.
    cpu: Fargate CPU units (256, 512, 1024, 2048, 4096).
    memory: Fargate memory MiB (512–8192).
    health_check_path: ALB health check path.
    public: true = public HTTPS endpoint; false = private.
    scaling: auto-scaling config.
    environment: environment variables.
    secrets: Secrets Manager or SSM secrets.
    subnet_ids: override default subnets.
    security_group_ids: override default security groups.
    task_role_arn: optional task role for AWS API access.
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

  validation {
    condition     = alltrue([for s in values(var.services) : contains([256, 512, 1024, 2048, 4096], s.cpu)])
    error_message = "cpu must be 256, 512, 1024, 2048, or 4096."
  }

  validation {
    condition = alltrue([
      for s in values(var.services) :
      contains(["AVERAGE_CPU", "AVERAGE_MEMORY", "REQUEST_COUNT_PER_TARGET"], s.scaling.metric)
    ])
    error_message = "scaling.metric must be AVERAGE_CPU, AVERAGE_MEMORY, or REQUEST_COUNT_PER_TARGET."
  }
}

# ================================================================= IAM / shared

variable "task_execution_role_arn" {
  description = "Existing ECS task execution role ARN. Leave null to create one."
  type        = string
  default     = null
}

variable "infrastructure_role_arn" {
  description = "Existing ECS infrastructure role ARN. Leave null to create one. Cannot be changed after service creation."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
