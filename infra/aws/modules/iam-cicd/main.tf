# IAM cho CI/CD (GitHub OIDC) — TÀI NGUYÊN DÙNG CHUNG dev+prod (envs/shared).
# 2 role tách bạch:
#   - sync-cicd-deploy : app-cicd.yml — push ECR + update ECS + RunTask (least-priv)
#   - sync-cicd-infra  : infra.yml   — terraform plan/apply (quyền rộng, chỉ repo/main)
# Task roles per-env nằm ở module iam-tasks.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "name" {
  type    = string
  default = "sync"
}
variable "github_repo" {
  description = "owner/repo được phép assume role"
  type        = string
}
variable "create_oidc_provider" {
  description = "false nếu account đã có provider token.actions.githubusercontent.com"
  type        = bool
  default     = true
}
variable "ecr_repository_arns" { type = list(string) }
variable "state_bucket" { type = string }
variable "lock_table" { type = string }
variable "region" { type = string }

data "aws_caller_identity" "current" {}

locals {
  oidc_url = "token.actions.githubusercontent.com"
  oidc_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_url}"
  subjects = [
    "repo:${var.github_repo}:ref:refs/heads/main",
    "repo:${var.github_repo}:pull_request",
    "repo:${var.github_repo}:environment:*",
  ]
  partition = "aws"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = "https://${local.oidc_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "assume_github" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "${local.oidc_url}:sub"
      values   = local.subjects
    }
  }
}

# ── Role 1: app deploy (least-priv) ─────────────────────────────────────────
resource "aws_iam_role" "deploy" {
  name               = "${var.name}-cicd-deploy"
  assume_role_policy = data.aws_iam_policy_document.assume_github.json
}

data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid = "EcrPush"
    actions = [
      "ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer", "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart", "ecr:CompleteLayerUpload", "ecr:PutImage",
      "ecr:DescribeImages", "ecr:DescribeRepositories",
    ]
    resources = var.ecr_repository_arns
  }
  statement {
    sid = "EcsDeploy"
    actions = [
      "ecs:DescribeServices", "ecs:DescribeTaskDefinition", "ecs:DescribeTasks",
      "ecs:ListTasks", "ecs:RegisterTaskDefinition", "ecs:UpdateService",
      "ecs:RunTask", "ecs:DescribeClusters", "ecs:TagResource",
    ]
    resources = ["*"]
  }
  statement {
    # Task roles per-env (sync-dev-task*, sync-prod-task*) tạo ở module iam-tasks
    sid     = "PassTaskRoles"
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/sync-*-task",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/sync-*-task-execution",
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
  statement {
    sid = "CodeDeployBlueGreen"
    actions = [
      "codedeploy:CreateDeployment", "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentGroup", "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision", "codedeploy:GetApplicationRevision",
      "codedeploy:ListDeployments", "codedeploy:StopDeployment",
    ]
    resources = ["arn:${local.partition}:codedeploy:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
  }
  statement {
    sid = "WebStaticS3"
    actions = [
      "s3:PutObject", "s3:DeleteObject", "s3:GetObject",
      "s3:ListBucket", "s3:AbortMultipartUpload", "s3:ListBucketMultipartUploads",
    ]
    resources = [
      "arn:aws:s3:::sync-web-*",
      "arn:aws:s3:::sync-web-*/*",
    ]
  }
  statement {
    sid = "WebCloudFrontInvalidate"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "cloudfront:ListInvalidations",
    ]
    resources = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "deploy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}

# ── Role 2: infra (terraform) — quyền rộng + state ──────────────────────────
resource "aws_iam_role" "infra" {
  name               = "${var.name}-cicd-infra"
  assume_role_policy = data.aws_iam_policy_document.assume_github.json
}

resource "aws_iam_role_policy_attachment" "infra_admin" {
  # Terraform quản lý gần như mọi resource → PowerUser + IAM giới hạn dưới.
  role       = aws_iam_role.infra.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "infra_iam" {
  statement {
    sid = "TerraformManagedIam"
    actions = [
      "iam:GetRole", "iam:CreateRole", "iam:DeleteRole", "iam:TagRole",
      "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole",
      "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
      "iam:GetInstanceProfile", "iam:PassRole", "iam:UpdateAssumeRolePolicy",
      "iam:CreateOpenIDConnectProvider", "iam:GetOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider", "iam:TagOpenIDConnectProvider",
      "iam:CreateServiceLinkedRole", "iam:ListRoleTags",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "TfState"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket}", "arn:aws:s3:::${var.state_bucket}/*"]
  }
  statement {
    sid       = "TfLock"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table}"]
  }
}

resource "aws_iam_role_policy" "infra_iam" {
  name   = "iam-and-state"
  role   = aws_iam_role.infra.id
  policy = data.aws_iam_policy_document.infra_iam.json
}

output "deploy_role_arn" { value = aws_iam_role.deploy.arn }
output "infra_role_arn" { value = aws_iam_role.infra.arn }
