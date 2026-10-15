# ----------------------------------------------------------------- ECR

output "repository_urls" {
  description = "ECR repository URLs keyed by repository name."
  value       = module.ecr.repository_urls
}

output "repository_arns" {
  description = "ECR repository ARNs keyed by repository name."
  value       = module.ecr.repository_arns
}

output "scan_type" {
  description = "Registry scanning mode in effect."
  value       = module.ecr_registry.scan_type
}

output "replication_registry_id" {
  description = "Registry ID for the replication configuration, or null."
  value       = module.ecr_registry.replication_registry_id
}

output "pull_through_cache_prefixes" {
  description = "Pull-through cache rule prefixes that were created."
  value       = module.ecr_registry.pull_through_cache_prefixes
}

# ----------------------------------------------------------------- ECS

output "cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs_express.cluster_name
}

output "cluster_arn" {
  description = "ECS cluster ARN, or null when an existing cluster was supplied."
  value       = module.ecs_express.cluster_arn
}

output "service_urls" {
  description = "Express Mode HTTPS URLs keyed by service name."
  value       = module.ecs_express.service_urls
}

output "service_names" {
  description = "ECS Express service names as created."
  value       = module.ecs_express.service_names
}

output "task_execution_role_arn" {
  description = "Task execution role ARN (created or supplied)."
  value       = module.iam.task_execution_role_arn
}

output "infrastructure_role_arn" {
  description = "Infrastructure role ARN (created or supplied)."
  value       = module.iam.infrastructure_role_arn
}

output "log_group_names" {
  description = "CloudWatch log group names keyed by service name."
  value       = module.ecs_express.log_group_names
}

# ----------------------------------------------------------------- Push helper

output "docker_push_commands" {
  description = "docker build/tag/push command sequence per repository."
  value = {
    for k, url in module.ecr.repository_urls : k => join("\n", [
      "aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${local.account}.dkr.ecr.${local.region}.amazonaws.com",
      "docker build -t ${var.name}/${k} .",
      "docker tag ${var.name}/${k}:latest ${url}:latest",
      "docker push ${url}:latest",
    ])
  }
}
