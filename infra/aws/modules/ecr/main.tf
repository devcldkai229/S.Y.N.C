# ECR: 1 repo/image `sync/<name>` — immutable tags + scan-on-push + lifecycle
# (giữ 20 image gần nhất, xoá untagged sau 7 ngày) để tiết kiệm dung lượng.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "repositories" {
  description = "Tên image (không kèm prefix sync/)"
  type        = list(string)
}
variable "keep_last" {
  type    = number
  default = 20
}

resource "aws_ecr_repository" "this" {
  for_each             = toset(var.repositories)
  name                 = "sync/${each.value}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep last ${var.keep_last} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.keep_last
        }
        action = { type = "expire" }
      }
    ]
  })
}

output "repository_urls" {
  value = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}
output "repository_arns" {
  value = { for k, r in aws_ecr_repository.this : k => r.arn }
}
