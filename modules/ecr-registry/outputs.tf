output "scan_type" {
  description = "Registry scanning mode in effect."
  value       = aws_ecr_registry_scanning_configuration.this.scan_type
}

output "replication_registry_id" {
  description = "Registry ID for the replication configuration, or null."
  value       = try(aws_ecr_replication_configuration.this[0].replication_configuration[0].rule[0].destination[0].registry_id, null)
}

output "pull_through_cache_prefixes" {
  description = "Pull-through cache rule prefixes that were created."
  value       = [for r in aws_ecr_pull_through_cache_rule.this : r.ecr_repository_prefix]
}

output "replication_count" {
  description = "Number of replication configurations created (0 or 1)."
  value       = length(aws_ecr_replication_configuration.this)
}

output "pull_through_cache_count" {
  description = "Number of pull-through cache rules created."
  value       = length(aws_ecr_pull_through_cache_rule.this)
}
