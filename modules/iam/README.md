# iam submodule

Creates the two IAM roles ECS Express Mode needs: a task execution role (with an
inline ECR pull policy scoped to the supplied repository ARNs) and the Express
Mode infrastructure role. Each role is created only when its ARN input is null,
so callers can supply existing roles instead.

The `ready` output is an opaque token a consumer can depend on to order
resources after the roles and their policy attachments exist.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.23 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.23 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.infra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.task_exec_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.infra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.infra_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_exec_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_exec_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecr_repository_arns"></a> [ecr\_repository\_arns](#input\_ecr\_repository\_arns) | ECR repository ARNs the task execution role may pull. Empty = no pull policy. | `list(string)` | `[]` | no |
| <a name="input_infrastructure_role_arn"></a> [infrastructure\_role\_arn](#input\_infrastructure\_role\_arn) | Existing infrastructure role ARN. When set, the module creates no infrastructure role. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Prefix for IAM role names. | `string` | n/a | yes |
| <a name="input_partition"></a> [partition](#input\_partition) | AWS partition, used to build managed policy ARNs. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to created roles. | `map(string)` | `{}` | no |
| <a name="input_task_execution_role_arn"></a> [task\_execution\_role\_arn](#input\_task\_execution\_role\_arn) | Existing task execution role ARN. When set, the module creates no execution role. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_infra_role_created_count"></a> [infra\_role\_created\_count](#output\_infra\_role\_created\_count) | 1 when this module created the infrastructure role, else 0. |
| <a name="output_infrastructure_role_arn"></a> [infrastructure\_role\_arn](#output\_infrastructure\_role\_arn) | Infrastructure role ARN (created or supplied). |
| <a name="output_ready"></a> [ready](#output\_ready) | Opaque dependency token. References the role policy attachments and inline<br/>policy so a consumer can order resources after the roles are fully usable. |
| <a name="output_task_exec_role_created_count"></a> [task\_exec\_role\_created\_count](#output\_task\_exec\_role\_created\_count) | 1 when this module created the task execution role, else 0. |
| <a name="output_task_execution_role_arn"></a> [task\_execution\_role\_arn](#output\_task\_execution\_role\_arn) | Task execution role ARN (created or supplied). |
<!-- END_TF_DOCS -->
