terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.23" }
  }
}

provider "aws" { region = "ap-south-1" }

module "container_platform" {
  source = "../../"
  name   = "acme"

  repositories = {
    api = {
      image_tag_mutability = "IMMUTABLE"
      lifecycle_rules = [
        { description = "Keep last 10 tagged", tag_status = "tagged", tag_prefix = "v", count_type = "imageCountMoreThan", count_number = 10 },
        { description = "Expire untagged after 7d", tag_status = "untagged", count_type = "sinceImagePushed", count_number = 7, count_unit = "days" },
      ]
    }
    worker = {
      lifecycle_rules = [{ description = "Keep last 5", tag_status = "any", count_type = "imageCountMoreThan", count_number = 5 }]
    }
  }

  scan_type  = "ENHANCED"
  scan_rules = [{ filter = "*", frequency = "CONTINUOUS_SCAN" }]

  replication_destinations = [{
    regions        = ["us-east-1", "eu-west-1"]
    prefix_filters = ["acme/"]
  }]

  pull_through_cache_rules = [
    { ecr_repository_prefix = "docker-hub", upstream_registry_url = "registry-1.docker.io" },
    { ecr_repository_prefix = "ecr-public", upstream_registry_url = "public.ecr.aws" },
  ]

  services = {
    api = {
      repository  = "api", image_tag = "v1.2.0", container_port = 8080
      cpu         = 1024, memory = 2048, health_check_path = "/health"
      scaling     = { metric = "REQUEST_COUNT_PER_TARGET", target_value = 60, min_tasks = 2, max_tasks = 20 }
      environment = [{ name = "APP_ENV", value = "production" }]
      secrets     = [{ name = "DATABASE_URL", value_from = "arn:aws:secretsmanager:ap-south-1:123456789012:secret:acme/db-url" }]
    }
    worker = {
      repository = "worker", image_tag = "v1.0.0", container_port = 9090
      cpu        = 512, memory = 1024, health_check_path = "/ready", public = false
      scaling    = { metric = "AVERAGE_CPU", target_value = 70, min_tasks = 1, max_tasks = 10 }
    }
  }

  tags = { Environment = "prod", ManagedBy = "terraform" }
}

output "service_urls" { value = module.container_platform.service_urls }
output "repository_urls" { value = module.container_platform.repository_urls }
output "docker_push_commands" { value = module.container_platform.docker_push_commands }
