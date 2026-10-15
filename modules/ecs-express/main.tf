# ----------------------------------------------------------------- Cluster

resource "aws_ecs_cluster" "this" {
  count = var.create_cluster ? 1 : 0
  name  = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# ----------------------------------------------------------------- Log groups

resource "aws_cloudwatch_log_group" "service" {
  for_each          = var.services
  name              = coalesce(each.value.log_group, "/ecs/${var.name}/${each.key}")
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ----------------------------------------------------------------- Express gateway services

resource "aws_ecs_express_gateway_service" "this" {
  for_each = var.services

  service_name            = "${var.name}-${each.key}"
  cluster                 = var.create_cluster ? aws_ecs_cluster.this[0].name : var.cluster_name
  execution_role_arn      = var.execution_role_arn
  infrastructure_role_arn = var.infrastructure_role_arn
  cpu                     = each.value.cpu
  memory                  = each.value.memory
  health_check_path       = each.value.health_check_path
  task_role_arn           = each.value.task_role_arn
  wait_for_steady_state   = each.value.wait_for_steady_state

  primary_container {
    image          = var.service_images[each.key]
    container_port = each.value.container_port

    aws_logs_configuration {
      log_group         = aws_cloudwatch_log_group.service[each.key].name
      log_stream_prefix = each.key
    }

    dynamic "environment" {
      for_each = each.value.environment
      content {
        name  = environment.value.name
        value = environment.value.value
      }
    }

    dynamic "secret" {
      for_each = each.value.secrets
      content {
        name       = secret.value.name
        value_from = secret.value.value_from
      }
    }
  }

  dynamic "network_configuration" {
    for_each = length(each.value.subnet_ids) > 0 ? [1] : []
    content {
      subnets         = each.value.subnet_ids
      security_groups = each.value.security_group_ids
    }
  }

  scaling_target {
    auto_scaling_metric       = each.value.scaling.metric
    auto_scaling_target_value = each.value.scaling.target_value
    min_task_count            = each.value.scaling.min_tasks
    max_task_count            = each.value.scaling.max_tasks
  }

  tags = var.tags
}
