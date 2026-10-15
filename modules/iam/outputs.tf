output "task_execution_role_arn" {
  description = "Task execution role ARN (created or supplied)."
  value       = coalesce(var.task_execution_role_arn, try(aws_iam_role.task_exec[0].arn, null))
}

output "infrastructure_role_arn" {
  description = "Infrastructure role ARN (created or supplied)."
  value       = coalesce(var.infrastructure_role_arn, try(aws_iam_role.infra[0].arn, null))
}

output "ready" {
  description = <<-EOT
    Opaque dependency token. References the role policy attachments and inline
    policy so a consumer can order resources after the roles are fully usable.
  EOT
  value = join(",", concat(
    aws_iam_role_policy_attachment.task_exec[*].id,
    aws_iam_role_policy_attachment.infra[*].id,
    aws_iam_role_policy.task_exec_ecr[*].id,
  ))
}

output "task_exec_role_created_count" {
  description = "1 when this module created the task execution role, else 0."
  value       = length(aws_iam_role.task_exec)
}

output "infra_role_created_count" {
  description = "1 when this module created the infrastructure role, else 0."
  value       = length(aws_iam_role.infra)
}
