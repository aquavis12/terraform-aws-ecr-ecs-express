mock_provider "aws" {
  mock_data "aws_caller_identity" { defaults = { account_id = "123456789012" } }
  mock_data "aws_region" { defaults = { region = "ap-south-1" } }
  mock_data "aws_partition" { defaults = { partition = "aws" } }
  mock_data "aws_iam_policy_document" { defaults = { json = "{}" } }
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::123456789012:role/mock" } }
  mock_resource "aws_ecs_cluster" { defaults = { arn = "arn:aws:ecs:ap-south-1:123456789012:cluster/mock", id = "t-cluster" } }
  mock_resource "aws_ecr_repository" { defaults = { arn = "arn:aws:ecr:ap-south-1:123456789012:repository/mock", repository_url = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/mock" } }
  mock_resource "aws_ecs_express_gateway_service" { defaults = { service_arn = "arn:aws:ecs:ap-south-1:123456789012:express-gateway-service/mock", ingress_paths = [{ access_type = "PUBLIC", endpoint = "https://mock.ecs.ap-south-1.on.aws" }] } }
}

variables {
  name = "t"
}

run "no_repos_no_services" {
  command = plan
  assert {
    condition     = length(module.ecr.repository_urls) == 0
    error_message = "No repos when none defined."
  }
  assert {
    condition     = module.ecs_express.service_count == 0
    error_message = "No services when none defined."
  }
  assert {
    condition     = module.ecs_express.cluster_created_count == 1
    error_message = "Cluster created by default."
  }
}

run "ecr_repos_created" {
  command = plan
  variables {
    repositories = {
      api    = { image_tag_mutability = "IMMUTABLE" }
      worker = {}
    }
  }
  assert {
    condition     = length(module.ecr.repository_urls) == 2
    error_message = "Two repos must be created."
  }
  assert {
    condition     = module.ecr.repository_mutability["api"] == "IMMUTABLE"
    error_message = "Mutability setting must be applied."
  }
}

run "lifecycle_policy_created_only_when_rules_defined" {
  command = plan
  variables {
    repositories = {
      with_rules    = { lifecycle_rules = [{ count_type = "imageCountMoreThan", count_number = 5 }] }
      without_rules = {}
    }
  }
  assert {
    condition     = module.ecr.lifecycle_policy_count == 1
    error_message = "Only one lifecycle policy for the repo with rules."
  }
}

run "enhanced_scanning_with_rules" {
  command = plan
  variables {
    scan_type = "ENHANCED"
    scan_rules = [
      { filter = "*", frequency = "CONTINUOUS_SCAN" },
      { filter = "prod/*", frequency = "SCAN_ON_PUSH" },
    ]
  }
  assert {
    condition     = module.ecr_registry.scan_type == "ENHANCED"
    error_message = "Scan type must be ENHANCED."
  }
}

run "basic_scanning_no_enhanced_rules" {
  command = plan
  variables {
    scan_type = "BASIC"
  }
  assert {
    condition     = module.ecr_registry.scan_type == "BASIC"
    error_message = "Scan type must be BASIC."
  }
}

run "replication_created" {
  command = plan
  variables {
    replication_destinations = [{
      regions        = ["us-east-1", "eu-west-1"]
      prefix_filters = ["t/"]
    }]
  }
  assert {
    condition     = module.ecr_registry.replication_count == 1
    error_message = "Replication config must be created."
  }
}

run "no_replication_by_default" {
  command = plan
  assert {
    condition     = module.ecr_registry.replication_count == 0
    error_message = "No replication when no destinations defined."
  }
}

run "pull_through_cache" {
  command = plan
  variables {
    pull_through_cache_rules = [
      { ecr_repository_prefix = "docker-hub", upstream_registry_url = "registry-1.docker.io" },
      { ecr_repository_prefix = "ecr-public", upstream_registry_url = "public.ecr.aws" },
    ]
  }
  assert {
    condition     = module.ecr_registry.pull_through_cache_count == 2
    error_message = "Two pull-through cache rules must be created."
  }
}

run "express_service_created" {
  command = plan
  variables {
    repositories = { api = {} }
    services = {
      api = {
        repository = "api"
        image_tag  = "v1.0.0"
        scaling    = { metric = "REQUEST_COUNT_PER_TARGET", target_value = 60, min_tasks = 2, max_tasks = 20 }
      }
    }
  }
  assert {
    condition     = module.ecs_express.service_count == 1
    error_message = "Express service must be created."
  }

}

run "iam_roles_auto_created" {
  command = plan
  assert {
    condition     = module.iam.task_exec_role_created_count == 1
    error_message = "Task exec role auto-created."
  }
  assert {
    condition     = module.iam.infra_role_created_count == 1
    error_message = "Infrastructure role auto-created."
  }
}

run "supplied_roles_skip_creation" {
  command = plan
  variables {
    task_execution_role_arn = "arn:aws:iam::123456789012:role/my-exec"
    infrastructure_role_arn = "arn:aws:iam::123456789012:role/my-infra"
  }
  assert {
    condition     = module.iam.task_exec_role_created_count == 0
    error_message = "No task exec role when one is supplied."
  }
  assert {
    condition     = module.iam.infra_role_created_count == 0
    error_message = "No infra role when one is supplied."
  }
}

run "existing_cluster_not_created" {
  command = plan
  variables {
    ecs_cluster_name = "my-existing-cluster"
  }
  assert {
    condition     = module.ecs_express.cluster_created_count == 0
    error_message = "Cluster must not be created when name is supplied."
  }
}

run "invalid_scan_frequency" {
  command = plan
  variables {
    scan_rules = [{ filter = "*", frequency = "WHENEVER_I_FEEL_LIKE_IT" }]
  }
  expect_failures = [var.scan_rules]
}

run "invalid_cpu" {
  command = plan
  variables {
    services = {
      bad = { repository = "api", cpu = 999 }
    }
  }
  expect_failures = [var.services]
}

run "docker_push_commands_output" {
  command = apply
  variables {
    repositories = { api = {} }
  }
  assert {
    condition     = strcontains(output.docker_push_commands["api"], "docker push")
    error_message = "Push commands must include docker push."
  }
}
