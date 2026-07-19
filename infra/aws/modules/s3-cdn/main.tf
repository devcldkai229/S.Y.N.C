# S3 thay MinIO: pub-assets (serve qua CloudFront + OAC) + private-assets
# (chỉ presigned URL). Tên bucket global-unique — code .NET mặc định
# "sync-pub-assets"/"sync-private-assets"; nếu bị trùng, đổi var + override
# config ObjectStorage Bucket qua env service.

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

resource "aws_s3_bucket" "public_assets" {
  bucket = var.public_bucket_name
}

resource "aws_s3_bucket" "private_assets" {
  bucket = var.private_bucket_name
}

resource "aws_s3_bucket_public_access_block" "public_assets" {
  bucket                  = aws_s3_bucket.public_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "private_assets" {
  bucket                  = aws_s3_bucket.private_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "public_assets" {
  bucket = aws_s3_bucket.public_assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private_assets" {
  bucket = aws_s3_bucket.private_assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "public_assets" {
  bucket = aws_s3_bucket.public_assets.id
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
    domain_name              = aws_s3_bucket.public_assets.bucket_regional_domain_name
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
    resources = ["${aws_s3_bucket.public_assets.arn}/*"]
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
  bucket = aws_s3_bucket.public_assets.id
  policy = data.aws_iam_policy_document.public_assets_cf[0].json
}

output "public_bucket" { value = aws_s3_bucket.public_assets.bucket }
output "private_bucket" { value = aws_s3_bucket.private_assets.bucket }
output "public_bucket_arn" { value = aws_s3_bucket.public_assets.arn }
output "private_bucket_arn" { value = aws_s3_bucket.private_assets.arn }
output "cdn_domain" { value = var.enable_cloudfront ? aws_cloudfront_distribution.public_assets[0].domain_name : null }
