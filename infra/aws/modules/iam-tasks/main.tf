# ECS task roles PER-ENV:
#   <name>-task-execution : pull image, logs, đọc secrets/SSM prefix /sync/<env>/*
#   <name>-task           : app runtime — S3 assets, AWS Location

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "name" { type = string } # vd sync-dev
variable "env" { type = string }
variable "region" { type = string }
variable "secrets_prefix_arn" { type = string }
variable "s3_bucket_arns" {
  type    = list(string)
  default = []
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_ecs_tasks" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name}-task-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_tasks.json
}

resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "task_execution_secrets" {
  statement {
    sid       = "ReadSecrets"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.secrets_prefix_arn]
  }
  statement {
    sid       = "ReadParams"
    actions   = ["ssm:GetParameters", "ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/sync/${var.env}/*"]
  }
}

resource "aws_iam_role_policy" "task_execution_secrets" {
  name   = "read-secrets"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.task_execution_secrets.json
}

resource "aws_iam_role" "task" {
  name               = "${var.name}-task"
  assume_role_policy = data.aws_iam_policy_document.assume_ecs_tasks.json
}

data "aws_iam_policy_document" "task_app" {
  dynamic "statement" {
    for_each = length(var.s3_bucket_arns) > 0 ? [1] : []
    content {
      sid = "S3Assets"
      actions = [
        "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket",
      ]
      resources = concat(var.s3_bucket_arns, [for a in var.s3_bucket_arns : "${a}/*"])
    }
  }
  statement {
    sid = "AwsLocation"
    actions = [
      "geo:SearchPlaceIndexForText", "geo:SearchPlaceIndexForPosition",
      "geo:GetPlace", "geo:CalculateRoute", "geo:GetMap*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "task_app" {
  name   = "app-runtime"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_app.json
}

output "task_execution_role_arn" { value = aws_iam_role.task_execution.arn }
output "task_role_arn" { value = aws_iam_role.task.arn }
