output "repository_urls" {
  description = "ECR repository URLs keyed by repository name."
  value       = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}

output "repository_arns" {
  description = "ECR repository ARNs keyed by repository name."
  value       = { for k, r in aws_ecr_repository.this : k => r.arn }
}

output "repository_names" {
  description = "ECR repository names keyed by repository key."
  value       = { for k, r in aws_ecr_repository.this : k => r.name }
}

output "lifecycle_policy_count" {
  description = "Number of lifecycle policies created."
  value       = length(aws_ecr_lifecycle_policy.this)
}

output "repository_mutability" {
  description = "image_tag_mutability keyed by repository key."
  value       = { for k, r in aws_ecr_repository.this : k => r.image_tag_mutability }
}
