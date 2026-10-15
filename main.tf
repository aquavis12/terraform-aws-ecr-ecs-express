data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition = data.aws_partition.current.partition
  region    = data.aws_region.current.region
  account   = data.aws_caller_identity.current.account_id

  cluster_name   = coalesce(var.ecs_cluster_name, "${var.name}-cluster")
  create_cluster = var.ecs_cluster_name == null

  # Resolve each service's image: use the created repo URL when the service
  # points at one of this module's repositories, otherwise treat repository as
  # a literal image reference.
  service_images = {
    for k, s in var.services : k =>
    contains(keys(var.repositories), s.repository)
    ? "${module.ecr.repository_urls[s.repository]}:${s.image_tag}"
    : "${s.repository}:${s.image_tag}"
  }
}

# ================================================================= ECR repositories

module "ecr" {
  source = "./modules/ecr"

  name         = var.name
  repositories = var.repositories
  scan_on_push = var.scan_type == "BASIC"
  tags         = var.tags
}

# ================================================================= ECR registry-level settings

module "ecr_registry" {
  source = "./modules/ecr-registry"

  account_id               = local.account
  scan_type                = var.scan_type
  scan_rules               = var.scan_rules
  replication_destinations = var.replication_destinations
  pull_through_cache_rules = var.pull_through_cache_rules
  registry_policy          = var.registry_policy
}

# ================================================================= IAM roles

module "iam" {
  source = "./modules/iam"

  name                    = var.name
  partition               = local.partition
  task_execution_role_arn = var.task_execution_role_arn
  infrastructure_role_arn = var.infrastructure_role_arn
  ecr_repository_arns     = values(module.ecr.repository_arns)
  tags                    = var.tags
}

# ================================================================= ECS Express services

module "ecs_express" {
  source = "./modules/ecs-express"

  name                    = var.name
  cluster_name            = local.cluster_name
  create_cluster          = local.create_cluster
  execution_role_arn      = module.iam.task_execution_role_arn
  infrastructure_role_arn = module.iam.infrastructure_role_arn
  service_images          = local.service_images
  services                = var.services
  log_retention_days      = var.log_retention_days
  tags                    = var.tags

  # Order services after the IAM roles are fully usable (trust + attachments).
  depends_on = [module.iam]
}
