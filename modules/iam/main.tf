locals {
  create_task_exec = var.task_execution_role_arn == null
  create_infra     = var.infrastructure_role_arn == null
  create_ecr_pull  = local.create_task_exec && length(var.ecr_repository_arns) > 0
}

# ----------------------------------------------------------------- Task execution role

data "aws_iam_policy_document" "task_exec_trust" {
  count = local.create_task_exec ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_exec" {
  count              = local.create_task_exec ? 1 : 0
  name               = "${var.name}-ecs-task-exec"
  assume_role_policy = data.aws_iam_policy_document.task_exec_trust[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "task_exec" {
  count      = local.create_task_exec ? 1 : 0
  role       = aws_iam_role.task_exec[0].name
  policy_arn = "arn:${var.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "task_exec_ecr" {
  count = local.create_ecr_pull ? 1 : 0

  statement {
    sid       = "ECRPull"
    actions   = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability"]
    resources = var.ecr_repository_arns
  }
  statement {
    sid       = "ECRAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "task_exec_ecr" {
  count  = local.create_ecr_pull ? 1 : 0
  name   = "ecr-pull"
  role   = aws_iam_role.task_exec[0].id
  policy = data.aws_iam_policy_document.task_exec_ecr[0].json
}

# ----------------------------------------------------------------- Infrastructure role

data "aws_iam_policy_document" "infra_trust" {
  count = local.create_infra ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "infra" {
  count              = local.create_infra ? 1 : 0
  name               = "${var.name}-ecs-infra"
  assume_role_policy = data.aws_iam_policy_document.infra_trust[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "infra" {
  count      = local.create_infra ? 1 : 0
  role       = aws_iam_role.infra[0].name
  policy_arn = "arn:${var.partition}:iam::aws:policy/AmazonECSInfrastructureRolePolicyForExpressMode"
}
