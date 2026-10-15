# Complete example

Creates two ECR repositories (`api`, `worker`) with per-repo lifecycle policies,
enhanced Inspector V2 scanning, cross-region replication, and pull-through cache
rules, then deploys two ECS Express Mode services backed by those repositories.
IAM roles (task execution + infrastructure) and the ECS cluster are created by
the module.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Before running, review and replace the placeholder values in `main.tf`:

- `region` in the `provider "aws"` block — the region you deploy into.
- `name` — the prefix applied to ECR repos, IAM roles, and ECS services.
- `repositories` — your own repository names and lifecycle rules.
- `replication_destinations` — the regions (and `prefix_filters`) you replicate to.
- `services[*].image_tag` — the image tags your pipeline publishes.
- `services[*].secrets[*].value_from` — your real Secrets Manager / SSM ARNs.
- `tags` — your tagging convention.

The services reference images that must exist in the repositories before they
can reach a steady state. Push an image to each repository first (see the
`docker_push_commands` output), then re-run `terraform apply` or let the service
converge once the image is available.

## Outputs

| Name | Description |
|---|---|
| `service_urls` | Express Mode HTTPS URLs keyed by service name. |
| `repository_urls` | ECR repository URLs keyed by repository name. |
| `docker_push_commands` | `docker build`/`tag`/`push` command sequence per repository. |
