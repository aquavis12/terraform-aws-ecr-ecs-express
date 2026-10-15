resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = "${var.name}/${each.key}"
  image_tag_mutability = each.value.image_tag_mutability
  force_delete         = each.value.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  dynamic "encryption_configuration" {
    for_each = each.value.kms_key_arn != null ? [1] : []
    content {
      encryption_type = "KMS"
      kms_key         = each.value.kms_key_arn
    }
  }

  tags = var.tags
}

locals {
  repos_with_rules = {
    for k, r in var.repositories : k => r
    if length(r.lifecycle_rules) > 0
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = local.repos_with_rules
  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      for i, rule in each.value.lifecycle_rules : {
        rulePriority = i + 1
        description  = rule.description
        selection = merge(
          {
            tagStatus   = rule.tag_status
            countType   = rule.count_type
            countNumber = rule.count_number
          },
          rule.tag_status == "tagged" && rule.tag_prefix != null ? { tagPrefixList = [rule.tag_prefix] } : {},
          rule.count_unit != null ? { countUnit = rule.count_unit } : {}
        )
        action = { type = "expire" }
      }
    ]
  })
}
