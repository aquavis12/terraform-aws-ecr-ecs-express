output "cluster_name" {
  description = "ECS cluster name in use."
  value       = var.create_cluster ? aws_ecs_cluster.this[0].name : var.cluster_name
}

output "cluster_arn" {
  description = "ECS cluster ARN, or null when an existing cluster was supplied."
  value       = try(aws_ecs_cluster.this[0].arn, null)
}

output "service_urls" {
  description = "Express Mode HTTPS URLs keyed by service name."
  value = {
    for k, svc in aws_ecs_express_gateway_service.this :
    k => try(one([for path in svc.ingress_paths : path.endpoint]), null)
  }
}

output "service_names" {
  description = "ECS Express service names as created."
  value       = { for k, svc in aws_ecs_express_gateway_service.this : k => svc.service_name }
}

output "log_group_names" {
  description = "CloudWatch log group names keyed by service name."
  value       = { for k, lg in aws_cloudwatch_log_group.service : k => lg.name }
}

output "cluster_created_count" {
  description = "1 when this module created the cluster, else 0."
  value       = length(aws_ecs_cluster.this)
}

output "service_count" {
  description = "Number of Express gateway services created."
  value       = length(aws_ecs_express_gateway_service.this)
}
