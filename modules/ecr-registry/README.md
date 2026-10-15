# ecr-registry submodule

Manages the account- and region-wide ECR registry settings: enhanced/basic
scanning configuration, cross-region (and cross-account) replication,
pull-through cache rules, and an optional registry policy.

These settings apply to the whole registry in the account and region, not to a
single repository. Instantiate this submodule once per account/region.

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
| [aws_ecr_pull_through_cache_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_pull_through_cache_rule) | resource |
| [aws_ecr_registry_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_policy) | resource |
| [aws_ecr_registry_scanning_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_scanning_configuration) | resource |
| [aws_ecr_replication_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_replication_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Account ID of the current registry. Used as the default replication destination registry. | `string` | n/a | yes |
| <a name="input_pull_through_cache_rules"></a> [pull\_through\_cache\_rules](#input\_pull\_through\_cache\_rules) | Pull-through cache rules for upstream registries.<br/>ecr\_repository\_prefix: prefix under which cached images land.<br/>upstream\_registry\_url: e.g. public.ecr.aws, registry-1.docker.io, gcr.io.<br/>credential\_arn: Secrets Manager secret ARN with registry credentials. | <pre>list(object({<br/>    ecr_repository_prefix = string<br/>    upstream_registry_url = string<br/>    credential_arn        = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_registry_policy"></a> [registry\_policy](#input\_registry\_policy) | JSON registry policy for cross-account pull access. Null = no policy. | `string` | `null` | no |
| <a name="input_replication_destinations"></a> [replication\_destinations](#input\_replication\_destinations) | Cross-region (and cross-account) replication destinations.<br/>account\_id: target account (omit for same-account cross-region).<br/>regions: list of destination regions.<br/>prefix\_filters: optional list of repo name prefixes to replicate (empty = all). | <pre>list(object({<br/>    account_id     = optional(string)<br/>    regions        = list(string)<br/>    prefix_filters = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_scan_rules"></a> [scan\_rules](#input\_scan\_rules) | Enhanced scanning rules. Each rule has a filter (repo name wildcard) and frequency.<br/>Applied only when scan\_type = ENHANCED. | <pre>list(object({<br/>    filter    = string<br/>    frequency = string<br/>  }))</pre> | `[]` | no |
| <a name="input_scan_type"></a> [scan\_type](#input\_scan\_type) | Registry-level scanning type: BASIC or ENHANCED. | `string` | `"ENHANCED"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pull_through_cache_count"></a> [pull\_through\_cache\_count](#output\_pull\_through\_cache\_count) | Number of pull-through cache rules created. |
| <a name="output_pull_through_cache_prefixes"></a> [pull\_through\_cache\_prefixes](#output\_pull\_through\_cache\_prefixes) | Pull-through cache rule prefixes that were created. |
| <a name="output_replication_count"></a> [replication\_count](#output\_replication\_count) | Number of replication configurations created (0 or 1). |
| <a name="output_replication_registry_id"></a> [replication\_registry\_id](#output\_replication\_registry\_id) | Registry ID for the replication configuration, or null. |
| <a name="output_scan_type"></a> [scan\_type](#output\_scan\_type) | Registry scanning mode in effect. |
<!-- END_TF_DOCS -->
