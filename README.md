# terraform-aws-ecr-ecs-express

Terraform module for **Amazon ECR** (full registry coverage) and **ECS Express Mode** .

Terraform owns the registry, the images' lifecycle, the IAM roles, and the Express Mode services. One module call stands up the repositories your pipeline pushes to and the services that run those images behind an AWS-managed HTTPS endpoint.

## What ECS Express Mode does for you

<cite index="123-1">An ECS Express Mode service reduces the complexity of deploying containerized applications by providing sensible defaults and automating the configuration of supporting AWS services. Three inputs — a container image, a task execution role, and an infrastructure role — are all that's needed. Express Mode orchestrates Fargate, load balancer with SSL/TLS, auto scaling policies, monitoring, and networking components.</cite>

<cite index="114-1">Each Express Mode service automatically receives an AWS-provided domain name. ECS Express Mode consolidates up to 25 services behind a single Application Load Balancer using intelligent rule-based routing. All resources provisioned by ECS Express Mode remain fully accessible in your account.</cite>

<cite index="113-1">Express Mode now supports custom task definitions, letting you reuse existing ECS application configurations and advanced task-level customisation including observability and security sidecars, custom container health checks, ulimits, Linux runtime settings, and FireLens for custom log routing.</cite>

## ECR features covered

| Feature | Variable |
|---|---|
| Per-repo lifecycle policies | `repositories[*].lifecycle_rules` |
| Image tag immutability | `repositories[*].image_tag_mutability` |
| KMS encryption per repo | `repositories[*].kms_key_arn` |
| Registry scanning (BASIC or ENHANCED) | `scan_type`, `scan_rules` |
| Cross-region / cross-account replication | `replication_destinations` |
| Pull-through cache (Docker Hub, ECR Public, GCR, Quay) | `pull_through_cache_rules` |
| Registry policy (cross-account pull) | `registry_policy` |

## Usage

```hcl
module "platform" {
  source = "github.com/aquavis12/terraform-aws-ecr-ecs-express?ref=v1.0.0"
  name   = "acme"

  repositories = {
    api = {
      image_tag_mutability = "IMMUTABLE"
      lifecycle_rules = [
        { description = "Keep last 10 releases", tag_status = "tagged", count_type = "imageCountMoreThan", count_number = 10 },
        { description = "Expire untagged after 7d", tag_status = "untagged", count_type = "sinceImagePushed", count_number = 7, count_unit = "days" },
      ]
    }
  }

  scan_type  = "ENHANCED"
  scan_rules = [{ filter = "*", frequency = "CONTINUOUS_SCAN" }]

  replication_destinations = [{ regions = ["us-east-1", "eu-west-1"] }]

  services = {
    api = {
      repository        = "api"
      image_tag         = "v1.2.0"
      container_port    = 8080
      health_check_path = "/health"
      scaling           = { metric = "REQUEST_COUNT_PER_TARGET", target_value = 60, min_tasks = 2, max_tasks = 20 }
    }
  }
}

output "url" { value = module.platform.service_urls }
```

## Examples

- [complete](https://github.com/aquavis12/terraform-aws-ecr-ecs-express/tree/master/examples/complete) — two ECR repositories with lifecycle policies, enhanced scanning, replication, and pull-through cache, plus two ECS Express Mode services, IAM roles, and a cluster.

## Submodules

The root module is a thin composition layer. It wires four focused submodules
together, each usable on its own:

| Submodule | Purpose |
|---|---|
| [`modules/ecr`](./modules/ecr) | Private repositories and their per-repo lifecycle policies. |
| [`modules/ecr-registry`](./modules/ecr-registry) | Account- and region-wide registry settings: scanning, replication, pull-through cache, registry policy. |
| [`modules/iam`](./modules/iam) | Task execution role (with ECR pull) and the Express Mode infrastructure role, each created only when an ARN is not supplied. |
| [`modules/ecs-express`](./modules/ecs-express) | ECS cluster, per-service log groups, and the Express gateway services. |

The root resolves cross-cutting values (account ID, partition, repository URLs,
role ARNs, service images) and passes them between the submodules.

## Known limitations

**Registry-level settings are account-wide.** `scan_type` (scanning configuration)
and `registry_policy` apply to the whole registry in the account and region, not to
a single repository. Running two copies of this module in the same account and
region will fight over those settings. Set them in one place.

**A service needs its image to exist before it stabilises.** Express Mode pulls the
tag named in `services[*].image_tag`. On a first apply the repository is empty, so
push an image (see the `docker_push_commands` output) before the service can reach a
steady state. Set `wait_for_steady_state = false` (the default) so the apply does not
block on an image that is not there yet.

**The infrastructure role cannot be changed after service creation.**
`infrastructure_role_arn` is fixed once a service exists. To change it you must
replace the service.

**Force delete is off by default.** A repository with images cannot be destroyed
unless `repositories[*].force_delete = true`. Leave it off in production so a
`terraform destroy` cannot wipe images that are still in use.

**Enhanced scanning has a cost.** `scan_type = "ENHANCED"` uses Amazon Inspector V2
and is billed per image per month. `BASIC` scans on push at no charge. Pick
`ENHANCED` deliberately.

## Requirements

- Terraform 1.7 or later.
- AWS provider 6.23 or later. `aws_ecs_express_gateway_service` was added in 6.23;
  earlier provider versions cannot create Express Mode services.
- The applier needs permission to manage ECR, ECS, IAM roles, CloudWatch log groups,
  and the registry-level scanning and replication configuration.
- Docker and the AWS CLI on the machine that builds and pushes images (the module
  emits the push commands; it does not build images).

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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecr"></a> [ecr](#module\_ecr) | ./modules/ecr | n/a |
| <a name="module_ecr_registry"></a> [ecr\_registry](#module\_ecr\_registry) | ./modules/ecr-registry | n/a |
| <a name="module_ecs_express"></a> [ecs\_express](#module\_ecs\_express) | ./modules/ecs-express | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ./modules/iam | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | ECS cluster name. Leave null to create a new cluster. | `string` | `null` | no |
| <a name="input_infrastructure_role_arn"></a> [infrastructure\_role\_arn](#input\_infrastructure\_role\_arn) | Existing ECS infrastructure role ARN. Leave null to create one. Cannot be changed after service creation. | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention in days. | `number` | `30` | no |
| <a name="input_name"></a> [name](#input\_name) | Module name prefix. Used for ECR repos, IAM roles and ECS services. | `string` | n/a | yes |
| <a name="input_pull_through_cache_rules"></a> [pull\_through\_cache\_rules](#input\_pull\_through\_cache\_rules) | Pull-through cache rules for upstream registries.<br/>ecr\_repository\_prefix: prefix under which cached images land.<br/>upstream\_registry\_url: e.g. public.ecr.aws, registry-1.docker.io, gcr.io.<br/>credential\_arn: Secrets Manager secret ARN with registry credentials (not needed for public.ecr.aws). | <pre>list(object({<br/>    ecr_repository_prefix = string<br/>    upstream_registry_url = string<br/>    credential_arn        = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_registry_policy"></a> [registry\_policy](#input\_registry\_policy) | JSON registry policy for cross-account pull access. Null = no policy. | `string` | `null` | no |
| <a name="input_replication_destinations"></a> [replication\_destinations](#input\_replication\_destinations) | Cross-region (and cross-account) replication destinations.<br/>account\_id: target account (omit or set to local account for same-account cross-region).<br/>regions: list of destination regions.<br/>prefix\_filters: optional list of repo name prefixes to replicate (empty = all). | <pre>list(object({<br/>    account_id     = optional(string)<br/>    regions        = list(string)<br/>    prefix_filters = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | ECR private repositories to create.<br/>name: repository name (appended to var.name as <name>/<repo>).<br/>image\_tag\_mutability: MUTABLE or IMMUTABLE.<br/>force\_delete: allow destroy when images exist.<br/>lifecycle\_rules: list of lifecycle policy rules in priority order.<br/>kms\_key\_arn: customer-managed key; null = AES256. | <pre>map(object({<br/>    image_tag_mutability = optional(string, "IMMUTABLE")<br/>    force_delete         = optional(bool, false)<br/>    kms_key_arn          = optional(string)<br/>    lifecycle_rules = optional(list(object({<br/>      description  = optional(string, "")<br/>      tag_status   = optional(string, "any")<br/>      tag_prefix   = optional(string)<br/>      count_type   = string # imageCountMoreThan | sinceImagePushed<br/>      count_number = number<br/>      count_unit   = optional(string) # days — only for sinceImagePushed<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_scan_rules"></a> [scan\_rules](#input\_scan\_rules) | Enhanced scanning rules. Each rule has a filter (repo name wildcard) and frequency.<br/>Frequency: SCAN\_ON\_PUSH \| CONTINUOUS\_SCAN \| MANUAL.<br/>Ignored when scan\_type = BASIC. | <pre>list(object({<br/>    filter    = string<br/>    frequency = string<br/>  }))</pre> | <pre>[<br/>  {<br/>    "filter": "*",<br/>    "frequency": "CONTINUOUS_SCAN"<br/>  }<br/>]</pre> | no |
| <a name="input_scan_type"></a> [scan\_type](#input\_scan\_type) | Registry-level scanning type: BASIC (on push, free) or ENHANCED (Inspector V2, per image/month). | `string` | `"ENHANCED"` | no |
| <a name="input_services"></a> [services](#input\_services) | ECS Express Mode services to deploy.<br/>repository: key from var.repositories — the image source.<br/>image\_tag: tag to deploy (e.g. latest, v1.2.3).<br/>container\_port: port the container listens on.<br/>cpu: Fargate CPU units (256, 512, 1024, 2048, 4096).<br/>memory: Fargate memory MiB (512–8192).<br/>health\_check\_path: ALB health check path.<br/>public: true = public HTTPS endpoint; false = private.<br/>scaling: auto-scaling config.<br/>environment: environment variables.<br/>secrets: Secrets Manager or SSM secrets.<br/>subnet\_ids: override default subnets.<br/>security\_group\_ids: override default security groups.<br/>task\_role\_arn: optional task role for AWS API access. | <pre>map(object({<br/>    repository            = string<br/>    image_tag             = optional(string, "latest")<br/>    container_port        = optional(number, 80)<br/>    cpu                   = optional(number, 1024)<br/>    memory                = optional(number, 2048)<br/>    health_check_path     = optional(string, "/health")<br/>    public                = optional(bool, true)<br/>    wait_for_steady_state = optional(bool, false)<br/>    task_role_arn         = optional(string)<br/>    subnet_ids            = optional(list(string), [])<br/>    security_group_ids    = optional(list(string), [])<br/><br/>    scaling = optional(object({<br/>      metric       = optional(string, "REQUEST_COUNT_PER_TARGET")<br/>      target_value = optional(number, 60)<br/>      min_tasks    = optional(number, 1)<br/>      max_tasks    = optional(number, 20)<br/>    }), {})<br/><br/>    environment = optional(list(object({<br/>      name  = string<br/>      value = string<br/>    })), [])<br/><br/>    secrets = optional(list(object({<br/>      name       = string<br/>      value_from = string<br/>    })), [])<br/><br/>    log_group = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every resource. | `map(string)` | `{}` | no |
| <a name="input_task_execution_role_arn"></a> [task\_execution\_role\_arn](#input\_task\_execution\_role\_arn) | Existing ECS task execution role ARN. Leave null to create one. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ECS cluster ARN, or null when an existing cluster was supplied. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | ECS cluster name. |
| <a name="output_docker_push_commands"></a> [docker\_push\_commands](#output\_docker\_push\_commands) | docker build/tag/push command sequence per repository. |
| <a name="output_infrastructure_role_arn"></a> [infrastructure\_role\_arn](#output\_infrastructure\_role\_arn) | Infrastructure role ARN (created or supplied). |
| <a name="output_log_group_names"></a> [log\_group\_names](#output\_log\_group\_names) | CloudWatch log group names keyed by service name. |
| <a name="output_pull_through_cache_prefixes"></a> [pull\_through\_cache\_prefixes](#output\_pull\_through\_cache\_prefixes) | Pull-through cache rule prefixes that were created. |
| <a name="output_replication_registry_id"></a> [replication\_registry\_id](#output\_replication\_registry\_id) | Registry ID for the replication configuration, or null. |
| <a name="output_repository_arns"></a> [repository\_arns](#output\_repository\_arns) | ECR repository ARNs keyed by repository name. |
| <a name="output_repository_urls"></a> [repository\_urls](#output\_repository\_urls) | ECR repository URLs keyed by repository name. |
| <a name="output_scan_type"></a> [scan\_type](#output\_scan\_type) | Registry scanning mode in effect. |
| <a name="output_service_names"></a> [service\_names](#output\_service\_names) | ECS Express service names as created. |
| <a name="output_service_urls"></a> [service\_urls](#output\_service\_urls) | Express Mode HTTPS URLs keyed by service name. |
| <a name="output_task_execution_role_arn"></a> [task\_execution\_role\_arn](#output\_task\_execution\_role\_arn) | Task execution role ARN (created or supplied). |
<!-- END_TF_DOCS -->

## Development

This repo uses [pre-commit](https://pre-commit.com/) to keep the code formatted,
linted, and documented. Hooks are defined in `.pre-commit-config.yaml` and run
`terraform fmt`, `terraform validate`, [TFLint](https://github.com/terraform-linters/tflint)
(config in `.tflint.hcl`), [terraform-docs](https://terraform-docs.io/), and
[Trivy](https://github.com/aquasecurity/trivy) for a security scan.

Install the tooling once:

```bash
pip install pre-commit            # or: brew install pre-commit
brew install tflint terraform-docs trivy   # or your platform's installer
pre-commit install                # register the git hook
```

Then the hooks run automatically on `git commit`. To run them against the whole
tree at any time:

```bash
pre-commit run --all-files
```

The `terraform_docs` hook regenerates the table block between the
`<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` markers above, so edit your
variables and outputs, not that block — it is overwritten on each run.

## Authors

Maintained by [vishnu](https://github.com/aquavis12).

## License

Apache-2.0 Licensed. See [LICENSE](./LICENSE).
