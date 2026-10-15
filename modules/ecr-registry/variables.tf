variable "account_id" {
  description = "Account ID of the current registry. Used as the default replication destination registry."
  type        = string
}

variable "scan_type" {
  description = "Registry-level scanning type: BASIC or ENHANCED."
  type        = string
  default     = "ENHANCED"
}

variable "scan_rules" {
  description = <<-EOT
    Enhanced scanning rules. Each rule has a filter (repo name wildcard) and frequency.
    Applied only when scan_type = ENHANCED.
  EOT
  type = list(object({
    filter    = string
    frequency = string
  }))
  default = []
}

variable "replication_destinations" {
  description = <<-EOT
    Cross-region (and cross-account) replication destinations.
    account_id: target account (omit for same-account cross-region).
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

variable "pull_through_cache_rules" {
  description = <<-EOT
    Pull-through cache rules for upstream registries.
    ecr_repository_prefix: prefix under which cached images land.
    upstream_registry_url: e.g. public.ecr.aws, registry-1.docker.io, gcr.io.
    credential_arn: Secrets Manager secret ARN with registry credentials.
  EOT
  type = list(object({
    ecr_repository_prefix = string
    upstream_registry_url = string
    credential_arn        = optional(string)
  }))
  default = []
}

variable "registry_policy" {
  description = "JSON registry policy for cross-account pull access. Null = no policy."
  type        = string
  default     = null
}
