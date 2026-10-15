# ecr submodule

Creates private ECR repositories (`<name>/<repo>`) and, for any repository that
defines `lifecycle_rules`, an `aws_ecr_lifecycle_policy`. Per-repo settings cover
image tag mutability, force delete, and optional KMS encryption.

Registry-wide settings (scanning, replication, pull-through cache) live in the
sibling [`ecr-registry`](../ecr-registry) submodule.

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
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Prefix for repository names. Each repo is created as <name>/<repo>. | `string` | n/a | yes |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | ECR private repositories to create, keyed by short name.<br/>image\_tag\_mutability: MUTABLE or IMMUTABLE.<br/>force\_delete: allow destroy when images exist.<br/>kms\_key\_arn: customer-managed key; null = AES256.<br/>lifecycle\_rules: list of lifecycle policy rules in priority order. | <pre>map(object({<br/>    image_tag_mutability = optional(string, "IMMUTABLE")<br/>    force_delete         = optional(bool, false)<br/>    kms_key_arn          = optional(string)<br/>    lifecycle_rules = optional(list(object({<br/>      description  = optional(string, "")<br/>      tag_status   = optional(string, "any")<br/>      tag_prefix   = optional(string)<br/>      count_type   = string<br/>      count_number = number<br/>      count_unit   = optional(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_scan_on_push"></a> [scan\_on\_push](#input\_scan\_on\_push) | Enable per-repository scan-on-push. Set true only for BASIC registry scanning. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every repository. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lifecycle_policy_count"></a> [lifecycle\_policy\_count](#output\_lifecycle\_policy\_count) | Number of lifecycle policies created. |
| <a name="output_repository_arns"></a> [repository\_arns](#output\_repository\_arns) | ECR repository ARNs keyed by repository name. |
| <a name="output_repository_mutability"></a> [repository\_mutability](#output\_repository\_mutability) | image\_tag\_mutability keyed by repository key. |
| <a name="output_repository_names"></a> [repository\_names](#output\_repository\_names) | ECR repository names keyed by repository key. |
| <a name="output_repository_urls"></a> [repository\_urls](#output\_repository\_urls) | ECR repository URLs keyed by repository name. |
<!-- END_TF_DOCS -->
