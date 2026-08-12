# Stack per-env: network → alb → cluster → data stores → secrets → services.
# envs/dev và envs/prod chỉ khác biến — toàn bộ wiring nằm ở đây (không drift).
# DNS/ACM CloudFront: provider alias aws.us_east_1 từ root env.

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
    random = { source = "hashicorp/random" }
  }
}

locals {
  name             = "sync-${var.env}"
  domain           = trimsuffix(var.domain_name, ".")
  enable_dns       = var.enable_dns && local.domain != ""
  enable_media_cdn = var.enable_media_cdn
  cf_zone_id       = "Z2FDTNDATAQYW2"
  api_base_url     = local.enable_dns ? "https://api.${local.domain}" : "http://${module.alb.alb_dns_name}"
  # Dev: media qua Gateway proxy. Prod: CDN edge URL.
  media_public_base_url = local.enable_media_cdn ? (
    local.enable_dns ? "https://cdn.${local.domain}" : "https://${module.s3_cdn.cdn_domain}"
  ) : "${local.api_base_url}/api/v1/media"
}

module "network" {
  source                     = "../network"
  name                       = local.name
  vpc_cidr                   = var.vpc_cidr
  nat_mode                   = var.nat_mode
  enable_interface_endpoints = var.enable_interface_endpoints
  region                     = var.region
}

module "alb" {
  source            = "../alb"
  name              = local.name
  vpc_id            = module.network.vpc_id
  vpc_cidr          = module.network.vpc_cidr
  public_subnet_ids = module.network.public_subnet_ids
  # enable_https is plan-time known (bool). ARN may still be unknown until ACM validates.
  enable_https     = local.enable_dns || var.certificate_arn != ""
  certificate_arn  = local.enable_dns ? module.dns[0].alb_certificate_arn : var.certificate_arn
  enable_bluegreen = var.enable_bluegreen
}

module "ecs_cluster" {
  source                = "../ecs-cluster"
  name                  = local.name # PHẢI khớp GitHub vars ECS_CLUSTER_DEV/PROD
  vpc_id                = module.network.vpc_id
  private_subnet_ids    = module.network.private_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  instance_type         = var.instance_type
  ondemand              = var.ondemand
  spot                  = var.spot
  namespace_name        = "${local.name}.local"
}

module "s3_cdn" {
  source = "../s3-cdn"
  # Shared existing buckets (data source) — không tạo sync-*-${env}
  public_bucket_name  = "sync-pub-assets"
  private_bucket_name = "sync-private-assets"
  enable_cloudfront   = local.enable_media_cdn
  aliases             = local.enable_media_cdn && local.enable_dns ? ["cdn.${local.domain}"] : []
  acm_certificate_arn = local.enable_media_cdn && local.enable_dns ? module.dns[0].cloudfront_certificate_arn : ""
}

# ── DNS: Route53 + ACM us-east-1 (CloudFront only — không tạo ACM ALB) ──────
module "dns" {
  count  = local.enable_dns ? 1 : 0
  source = "../dns"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  domain_name        = local.domain
  create_hosted_zone = var.create_hosted_zone
  name_prefix        = local.name
}

module "web_static" {
  source = "../web-static"

  env                 = var.env
  aliases             = local.enable_dns ? [local.domain, "www.${local.domain}"] : []
  acm_certificate_arn = local.enable_dns ? module.dns[0].cloudfront_certificate_arn : ""
}

# Route53 aliases (sau khi có ALB + CF domain names)
resource "aws_route53_record" "api_a" {
  count   = local.enable_dns ? 1 : 0
  zone_id = module.dns[0].zone_id
  name    = "api.${local.domain}"
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api_aaaa" {
  count   = local.enable_dns ? 1 : 0
  zone_id = module.dns[0].zone_id
  name    = "api.${local.domain}"
  type    = "AAAA"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cdn_a" {
  count   = local.enable_dns ? 1 : 0
  zone_id = module.dns[0].zone_id
  name    = "cdn.${local.domain}"
  type    = "A"

  alias {
    name                   = module.s3_cdn.cdn_domain
    zone_id                = local.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cdn_aaaa" {
  count   = local.enable_dns && local.enable_media_cdn ? 1 : 0
  zone_id = module.dns[0].zone_id
  name    = "cdn.${local.domain}"
  type    = "AAAA"

  alias {
    name                   = module.s3_cdn.cdn_domain
    zone_id                = local.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "web_a" {
  count   = local.enable_dns ? 1 : 0
  zone_id = module.dns[0].zone_id
  name    = local.domain
  type    = "A"

  alias {
    name                   = module.web_static.distribution_domain
    zone_id                = local.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "web_aaaa" {
  count   = local.enable_dns ? 1 : 0
  zone_id = module.dns[0].zone_id
  name    = local.domain
  type    = "AAAA"

  alias {
    name                   = module.web_static.distribution_domain
    zone_id                = local.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  count   = local.enable_dns ? 1 : 0
  zone_id = module.dns[0].zone_id
  name    = "www.${local.domain}"
  type    = "A"

  alias {
    name                   = module.web_static.distribution_domain
    zone_id                = local.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  count   = local.enable_dns ? 1 : 0
  zone_id = module.dns[0].zone_id
  name    = "www.${local.domain}"
  type    = "AAAA"

  alias {
    name                   = module.web_static.distribution_domain
    zone_id                = local.cf_zone_id
    evaluate_target_health = false
  }
}

module "rds" {
  source                     = "../rds"
  name                       = local.name
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  allowed_security_group_ids = [module.ecs_cluster.instances_security_group_id]
  instance_class             = var.rds_instance_class
  multi_az                   = var.rds_multi_az
  deletion_protection        = var.rds_deletion_protection
  skip_final_snapshot        = var.rds_skip_final_snapshot
}

module "redis" {
  source                     = "../redis"
  name                       = local.name
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  allowed_security_group_ids = [module.ecs_cluster.instances_security_group_id]
}

module "sqs" {
  source = "../sqs"
  name   = local.name
}

module "mongo" {
  source                     = "../mongo-ec2"
  name                       = local.name
  vpc_id                     = module.network.vpc_id
  private_subnet_id          = module.network.private_subnet_ids[0]
  allowed_security_group_ids = [module.ecs_cluster.instances_security_group_id]
  instance_type              = var.mongo_instance_type
}

# ── DB creds: chỉ password nằm trong Secrets Manager; phần còn lại (host/port/
#    user) là config thường → SSM Parameter Store. App tự ghép connection string.
locals {
  pg_host = module.rds.endpoint
  pg_user = module.rds.username
  pg_pass = module.rds.password

  # Secret hạ tầng TF sinh — CHỈ password (app ghép connection string từ đây + SSM)
  managed_secrets = {
    "db/postgres-password" = local.pg_pass
    "db/mongo-password"    = module.mongo.password
  }

  # Config thường TF biết giá trị → SSM (miễn phí, không tính như Secrets Manager)
  ssm_params = {
    "db/pg-host"    = local.pg_host
    "db/pg-port"    = "5432"
    "db/pg-user"    = local.pg_user
    "db/mongo-host" = module.mongo.private_ip
    "db/mongo-user" = module.mongo.username
  }

  # Secret THẬT người vận hành điền — GIỮ trong Secrets Manager
  # (aws secretsmanager put-secret-value)
  shell_secrets = [
    "shared/jwt-secret",
    "shared/internal-api-key",
    "llm/openai-api-key",
    "llm/tavily-api-key",
    "pay/payos-client-id",
    "pay/payos-api-key",
    "pay/payos-checksum-key",
    "delivery/ahamove-api-key",
    "mail/brevo-password",
    "ai/langfuse-secret-key",
  ]

  # Config KHÔNG nhạy cảm người vận hành điền → SSM Parameter Store
  # (aws ssm put-parameter --overwrite)
  ssm_shell_params = [
    "auth/google-client-ids",
    "ai/langfuse-public-key",
    "delivery/ahamove-mobile",
    "mail/brevo-username",
    "mail/brevo-from-email",
    "web/aws-map-api-key",
  ]
}

module "secrets" {
  source               = "../secrets"
  env                  = var.env
  region               = var.region
  shell_secrets        = local.shell_secrets
  managed_secrets      = local.managed_secrets
  ssm_params           = local.ssm_params
  ssm_shell_params     = local.ssm_shell_params
  recovery_window_days = var.secrets_recovery_window_days
}

module "iam_tasks" {
  source             = "../iam-tasks"
  name               = local.name
  env                = var.env
  region             = var.region
  secrets_prefix_arn = module.secrets.secret_prefix_arn
  s3_bucket_arns     = [module.s3_cdn.public_bucket_arn, module.s3_cdn.private_bucket_arn]
  sqs_queue_arns     = [module.sqs.queue_arn, module.sqs.dlq_arn]
}

module "observability" {
  source                  = "../observability"
  name                    = local.name
  alert_email             = var.alert_email
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_blue_arn_suffix
  rds_identifier          = module.rds.instance_identifier
}

# CodeDeploy blue/green cho gateway (prod)
module "codedeploy_gateway" {
  count                   = var.enable_bluegreen ? 1 : 0
  source                  = "../codedeploy-ecs"
  name                    = "${local.name}-gateway" # khớp ecs-bluegreen.sh
  cluster_name            = module.ecs_cluster.cluster_name
  service_name            = module.ecs_service["gateway"].service_name
  prod_listener_arn       = module.alb.prod_listener_arn
  test_listener_arn       = module.alb.test_listener_arn
  target_group_blue_name  = module.alb.target_group_blue_name
  target_group_green_name = module.alb.target_group_green_name
}
