# ecs-express submodule

Creates the ECS cluster (unless an existing cluster name is supplied), a
CloudWatch log group per service, and an `aws_ecs_express_gateway_service` for
each entry in `services`. Each service gets Fargate compute, an ALB-fronted
HTTPS endpoint, and target-tracking auto scaling, all managed by Express Mode.

Image references are resolved by the caller and passed in as `service_images`.

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
| [aws_cloudwatch_log_group.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_express_gateway_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_express_gateway_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the ECS cluster to run services in. The cluster is created here when create\_cluster is true. | `string` | n/a | yes |
| <a name="input_create_cluster"></a> [create\_cluster](#input\_create\_cluster) | Create the ECS cluster. False when an existing cluster name was supplied. | `bool` | `true` | no |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | Task execution role ARN used by every service. | `string` | n/a | yes |
| <a name="input_infrastructure_role_arn"></a> [infrastructure\_role\_arn](#input\_infrastructure\_role\_arn) | Infrastructure role ARN used by Express Mode to manage ALB, scaling, and networking. | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention in days. | `number` | `30` | no |
| <a name="input_name"></a> [name](#input\_name) | Prefix for the cluster and service names. | `string` | n/a | yes |
| <a name="input_service_images"></a> [service\_images](#input\_service\_images) | Fully-qualified container image reference (repo:tag) keyed by service name. | `map(string)` | `{}` | no |
| <a name="input_services"></a> [services](#input\_services) | ECS Express Mode services to deploy, keyed by short name.<br/>See the root module variable of the same name for field documentation. | <pre>map(object({<br/>    repository            = string<br/>    image_tag             = optional(string, "latest")<br/>    container_port        = optional(number, 80)<br/>    cpu                   = optional(number, 1024)<br/>    memory                = optional(number, 2048)<br/>    health_check_path     = optional(string, "/health")<br/>    public                = optional(bool, true)<br/>    wait_for_steady_state = optional(bool, false)<br/>    task_role_arn         = optional(string)<br/>    subnet_ids            = optional(list(string), [])<br/>    security_group_ids    = optional(list(string), [])<br/><br/>    scaling = optional(object({<br/>      metric       = optional(string, "REQUEST_COUNT_PER_TARGET")<br/>      target_value = optional(number, 60)<br/>      min_tasks    = optional(number, 1)<br/>      max_tasks    = optional(number, 20)<br/>    }), {})<br/><br/>    environment = optional(list(object({<br/>      name  = string<br/>      value = string<br/>    })), [])<br/><br/>    secrets = optional(list(object({<br/>      name       = string<br/>      value_from = string<br/>    })), [])<br/><br/>    log_group = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ECS cluster ARN, or null when an existing cluster was supplied. |
| <a name="output_cluster_created_count"></a> [cluster\_created\_count](#output\_cluster\_created\_count) | 1 when this module created the cluster, else 0. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | ECS cluster name in use. |
| <a name="output_log_group_names"></a> [log\_group\_names](#output\_log\_group\_names) | CloudWatch log group names keyed by service name. |
| <a name="output_service_count"></a> [service\_count](#output\_service\_count) | Number of Express gateway services created. |
| <a name="output_service_names"></a> [service\_names](#output\_service\_names) | ECS Express service names as created. |
| <a name="output_service_urls"></a> [service\_urls](#output\_service\_urls) | Express Mode HTTPS URLs keyed by service name. |
<!-- END_TF_DOCS -->
