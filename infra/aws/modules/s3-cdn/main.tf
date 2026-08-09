# S3 thay MinIO: dùng bucket CÓ SẴN (data source) — TF không sở hữu /
# không destroy bucket. CloudFront + OAC + bucket policy do TF quản.
# Dev/prod chung bucket → tách bằng Storage__KeyPrefix = "<env>/" trên ECS.
#
# Tên mặc định khớp app (.NET StorageBuckets / Flutter MediaUrlResolver):
#   sync-pub-assets / sync-private-assets

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "public_bucket_name" {
  type    = string
  default = "sync-pub-assets"
}
variable "private_bucket_name" {
  type    = string
  default = "sync-private-assets"
}
variable "enable_cloudfront" {
  type    = bool
  default = true
}

data "aws_s3_bucket" "public_assets" {
  bucket = var.public_bucket_name
}

data "aws_s3_bucket" "private_assets" {
  bucket = var.private_bucket_name
}

# CORS cho pub-assets (idempotent; không tạo/xoá bucket)
resource "aws_s3_bucket_cors_configuration" "public_assets" {
  bucket = data.aws_s3_bucket.public_assets.id
  cors_rule {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    max_age_seconds = 86400
  }
}

# ── CloudFront + OAC cho pub-assets ─────────────────────────────────────────
resource "aws_cloudfront_origin_access_control" "this" {
  count                             = var.enable_cloudfront ? 1 : 0
  name                              = "${var.public_bucket_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "public_assets" {
  count               = var.enable_cloudfront ? 1 : 0
  enabled             = true
  comment             = "SYNC public assets"
  default_root_object = ""
  price_class         = "PriceClass_200" # gồm Singapore/Asia

  origin {
    domain_name              = data.aws_s3_bucket.public_assets.bucket_regional_domain_name
    origin_id                = "s3-public-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
  }

  default_cache_behavior {
    target_origin_id       = "s3-public-assets"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    # AWS managed CachingOptimized
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_iam_policy_document" "public_assets_cf" {
  count = var.enable_cloudfront ? 1 : 0
  statement {
    sid       = "AllowCloudFrontOAC"
    actions   = ["s3:GetObject"]
    resources = ["${data.aws_s3_bucket.public_assets.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.public_assets[0].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "public_assets" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = data.aws_s3_bucket.public_assets.id
  policy = data.aws_iam_policy_document.public_assets_cf[0].json
}

output "public_bucket" { value = data.aws_s3_bucket.public_assets.bucket }
output "private_bucket" { value = data.aws_s3_bucket.private_assets.bucket }
output "public_bucket_arn" { value = data.aws_s3_bucket.public_assets.arn }
output "private_bucket_arn" { value = data.aws_s3_bucket.private_assets.arn }
output "cdn_domain" { value = var.enable_cloudfront ? aws_cloudfront_distribution.public_assets[0].domain_name : null }
