# Private S3 + CloudFront OAC for Next.js static export (ui/web → out/).
# Bucket: sync-web-<env> (TF-owned). Distinct from media sync-pub/private-assets.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "env" {
  type = string
}

variable "aliases" {
  description = "Custom domains (apex + www). Empty → default *.cloudfront.net cert."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "us-east-1 ACM ARN when aliases set"
  type        = string
  default     = ""
}

variable "price_class" {
  type    = string
  default = "PriceClass_200"
}

locals {
  bucket_name    = "sync-web-${var.env}"
  use_custom_ssl = length(var.aliases) > 0 && var.acm_certificate_arn != ""
  # CloudFront hosted zone ID is global for all distributions
  cf_hosted_zone_id = "Z2FDTNDATAQYW2"
}

resource "aws_s3_bucket" "web" {
  bucket = local.bucket_name
  tags = {
    Name = local.bucket_name
    env  = var.env
  }
}

resource "aws_s3_bucket_public_access_block" "web" {
  bucket                  = aws_s3_bucket.web.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "web" {
  bucket = aws_s3_bucket.web.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "web" {
  bucket = aws_s3_bucket.web.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "web" {
  name                              = "${local.bucket_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Next export: /about/ → /about/index.html ; /about → /about/index.html
resource "aws_cloudfront_function" "uri_rewrite" {
  name    = "sync-web-${var.env}-uri-rewrite"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOF
    function handler(event) {
      var request = event.request;
      var uri = request.uri;
      if (uri.endsWith('/')) {
        request.uri = uri + 'index.html';
      } else if (!uri.includes('.')) {
        request.uri = uri + '/index.html';
      }
      return request;
    }
  EOF
}

resource "aws_cloudfront_distribution" "web" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "SYNC web ${var.env}"
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = local.use_custom_ssl ? var.aliases : []

  origin {
    domain_name              = aws_s3_bucket.web.bucket_regional_domain_name
    origin_id                = "s3-web"
    origin_access_control_id = aws_cloudfront_origin_access_control.web.id
  }

  # HTML / pages — short TTL
  default_cache_behavior {
    target_origin_id       = "s3-web"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    # CachingDisabled (managed) — HTML must revalidate after deploy
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.uri_rewrite.arn
    }
  }

  # Immutable hashed assets
  ordered_cache_behavior {
    path_pattern           = "/_next/static/*"
    target_origin_id       = "s3-web"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    # CachingOptimized
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = local.use_custom_ssl ? [1] : []
    content {
      acm_certificate_arn      = var.acm_certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = local.use_custom_ssl ? [] : [1]
    content {
      cloudfront_default_certificate = true
    }
  }
}

data "aws_iam_policy_document" "web_oac" {
  statement {
    sid       = "AllowCloudFrontOAC"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.web.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.web.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "web" {
  bucket = aws_s3_bucket.web.id
  policy = data.aws_iam_policy_document.web_oac.json
}

output "bucket_name" {
  value = aws_s3_bucket.web.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.web.arn
}

output "distribution_id" {
  value = aws_cloudfront_distribution.web.id
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.web.arn
}

output "distribution_domain" {
  value = aws_cloudfront_distribution.web.domain_name
}

output "hosted_zone_id" {
  value = local.cf_hosted_zone_id
}
