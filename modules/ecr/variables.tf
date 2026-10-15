variable "name" {
  description = "Prefix for repository names. Each repo is created as <name>/<repo>."
  type        = string
}

variable "repositories" {
  description = <<-EOT
    ECR private repositories to create, keyed by short name.
    image_tag_mutability: MUTABLE or IMMUTABLE.
    force_delete: allow destroy when images exist.
    kms_key_arn: customer-managed key; null = AES256.
    lifecycle_rules: list of lifecycle policy rules in priority order.
  EOT
  type = map(object({
    image_tag_mutability = optional(string, "IMMUTABLE")
    force_delete         = optional(bool, false)
    kms_key_arn          = optional(string)
    lifecycle_rules = optional(list(object({
      description  = optional(string, "")
      tag_status   = optional(string, "any")
      tag_prefix   = optional(string)
      count_type   = string
      count_number = number
      count_unit   = optional(string)
    })), [])
  }))
  default = {}
}

variable "scan_on_push" {
  description = "Enable per-repository scan-on-push. Set true only for BASIC registry scanning."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every repository."
  type        = map(string)
  default     = {}
}
