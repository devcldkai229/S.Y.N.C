# SHARED (dùng chung dev+prod): ECR 13 repo + GitHub OIDC roles.
# Apply TRƯỚC dev/prod (dev/prod đọc outputs qua remote state).

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}
variable "github_repo" {
  type    = string
  default = "devcldkai229/S.Y.N.C"
}
variable "state_bucket" {
  description = "Bucket state từ bootstrap (sync-tfstate-<account>)"
  type        = string
}
variable "lock_table" {
  type    = string
  default = "sync-tf-lock"
}
variable "create_oidc_provider" {
  description = "false when account already has token.actions.githubusercontent.com (EntityAlreadyExists otherwise)"
  type        = bool
  default     = false
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      project    = "sync"
      env        = "shared"
      managed-by = "terraform"
    }
  }
}

locals {
  # 12 repo — khớp app-cicd.yml matrix (ai-worker dùng chung image "ai")
  repositories = [
    "gateway", "iam", "roadmap", "exercise", "nutrition", "marketplace",
    "order", "payment", "notification", "social", "ai", "rcm",
  ]
}

module "ecr" {
  source       = "../../modules/ecr"
  repositories = local.repositories
}

module "iam_cicd" {
  source               = "../../modules/iam-cicd"
  github_repo          = var.github_repo
  create_oidc_provider = var.create_oidc_provider
  ecr_repository_arns  = values(module.ecr.repository_arns)
  state_bucket         = var.state_bucket
  lock_table           = var.lock_table
  region               = var.region
}

output "ecr_repository_urls" { value = module.ecr.repository_urls }
output "deploy_role_arn" {
  description = "→ GitHub secret AWS_OIDC_ROLE_ARN (app-cicd.yml)"
  value       = module.iam_cicd.deploy_role_arn
}
output "infra_role_arn" {
  description = "→ GitHub secret AWS_OIDC_ROLE_ARN_INFRA (infra.yml)"
  value       = module.iam_cicd.infra_role_arn
}
