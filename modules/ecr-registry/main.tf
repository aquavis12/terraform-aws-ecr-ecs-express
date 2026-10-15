# ----------------------------------------------------------------- Scanning configuration

resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = var.scan_type

  dynamic "rule" {
    for_each = var.scan_type == "ENHANCED" ? var.scan_rules : []
    content {
      scan_frequency = rule.value.frequency
      repository_filter {
        filter      = rule.value.filter
        filter_type = "WILDCARD"
      }
    }
  }
}

# ----------------------------------------------------------------- Cross-region replication

locals {
  replication_rules = [
    for dest in var.replication_destinations : {
      destinations = [
        for r in dest.regions : {
          region      = r
          registry_id = coalesce(dest.account_id, var.account_id)
        }
      ]
      repository_filter = [
        for p in dest.prefix_filters : {
          filter      = p
          filter_type = "PREFIX_MATCH"
        }
      ]
    }
  ]
}

resource "aws_ecr_replication_configuration" "this" {
  count = length(var.replication_destinations) > 0 ? 1 : 0

  replication_configuration {
    dynamic "rule" {
      for_each = local.replication_rules
      content {
        dynamic "destination" {
          for_each = rule.value.destinations
          content {
            region      = destination.value.region
            registry_id = destination.value.registry_id
          }
        }
        dynamic "repository_filter" {
          for_each = rule.value.repository_filter
          content {
            filter      = repository_filter.value.filter
            filter_type = repository_filter.value.filter_type
          }
        }
      }
    }
  }
}

# ----------------------------------------------------------------- Pull-through cache

resource "aws_ecr_pull_through_cache_rule" "this" {
  for_each = { for r in var.pull_through_cache_rules : r.ecr_repository_prefix => r }

  ecr_repository_prefix = each.value.ecr_repository_prefix
  upstream_registry_url = each.value.upstream_registry_url
  credential_arn        = each.value.credential_arn
}

# ----------------------------------------------------------------- Registry policy

resource "aws_ecr_registry_policy" "this" {
  count  = var.registry_policy != null ? 1 : 0
  policy = var.registry_policy
}
