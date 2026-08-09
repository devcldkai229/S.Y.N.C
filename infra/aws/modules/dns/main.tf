# Route53 hosted zone + ACM:
#   - CloudFront certs: us-east-1 (aws.us_east_1)
#   - ALB cert (api.<domain>): default region (ap-southeast-1)
# Caller must pass provider alias: providers = { aws.us_east_1 = aws.us_east_1 }

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

variable "domain_name" {
  description = "Apex domain, e.g. sync.vn"
  type        = string
}

variable "create_hosted_zone" {
  description = "true = tạo zone mới; false = data zone đã có"
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Tag / comment prefix, e.g. sync-prod"
  type        = string
  default     = "sync"
}

locals {
  domain = trimsuffix(var.domain_name, ".")
}

resource "aws_route53_zone" "this" {
  count = var.create_hosted_zone ? 1 : 0
  name  = local.domain
  tags = {
    Name = "${var.name_prefix}-${local.domain}"
  }
}

data "aws_route53_zone" "this" {
  count        = var.create_hosted_zone ? 0 : 1
  name         = local.domain
  private_zone = false
}

locals {
  zone_id = var.create_hosted_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.this[0].zone_id
}

# ── ACM us-east-1 (CloudFront requirement) ──────────────────────────────────
resource "aws_acm_certificate" "cloudfront" {
  provider                  = aws.us_east_1
  domain_name               = local.domain
  subject_alternative_names = ["www.${local.domain}", "cdn.${local.domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name_prefix}-cf-${local.domain}"
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.zone_id
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}

# ── ACM regional (ALB HTTPS for api.<domain>) ───────────────────────────────
resource "aws_acm_certificate" "alb" {
  domain_name       = "api.${local.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name_prefix}-alb-api-${local.domain}"
  }
}

resource "aws_route53_record" "acm_validation_alb" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : "alb-${dvo.domain_name}" => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.zone_id
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation_alb : r.fqdn]
}

output "zone_id" {
  value = local.zone_id
}

output "cloudfront_certificate_arn" {
  description = "Validated ACM ARN in us-east-1 for CloudFront"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}

output "alb_certificate_arn" {
  description = "Validated ACM ARN in region for ALB (api.<domain>)"
  value       = aws_acm_certificate_validation.alb.certificate_arn
}

output "api_fqdn" {
  value = "api.${local.domain}"
}

output "cdn_fqdn" {
  value = "cdn.${local.domain}"
}

output "web_fqdn" {
  value = local.domain
}

output "www_fqdn" {
  value = "www.${local.domain}"
}

output "name_servers" {
  description = "Trỏ NS tại registrar khi create_hosted_zone=true"
  value       = var.create_hosted_zone ? aws_route53_zone.this[0].name_servers : data.aws_route53_zone.this[0].name_servers
}
