# Stack per-env: network → alb → cluster → data stores → secrets → services.
# envs/dev và envs/prod chỉ khác biến — toàn bộ wiring nằm ở đây (không drift).

terraform {
  required_providers {
    aws    = { source = "hashicorp/aws" }
    random = { source = "hashicorp/random" }
  }
}

locals {
  name = "sync-${var.env}"
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
  certificate_arn   = var.certificate_arn
  enable_bluegreen  = var.enable_bluegreen
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
  source              = "../s3-cdn"
  public_bucket_name  = "sync-pub-assets-${var.env}"
  private_bucket_name = "sync-private-assets-${var.env}"
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

module "mq" {
  source                     = "../mq"
  name                       = local.name
  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  allowed_security_group_ids = [module.ecs_cluster.instances_security_group_id]
  deployment_mode            = var.mq_deployment_mode
}

module "mongo" {
  source                     = "../mongo-ec2"
  name                       = local.name
  vpc_id                     = module.network.vpc_id
  private_subnet_id          = module.network.private_subnet_ids[0]
  allowed_security_group_ids = [module.ecs_cluster.instances_security_group_id]
  instance_type              = var.mongo_instance_type
}

# ── Ghép connection strings (TF-managed secrets) ────────────────────────────
locals {
  pg_host = module.rds.endpoint
  pg_user = module.rds.username
  pg_pass = module.rds.password

  pg_conn = { for db in ["sync_iam", "sync_order", "sync_payment", "sync_smartpush"] :
    db => "Host=${local.pg_host};Port=5432;Database=${db};Username=${local.pg_user};Password=${local.pg_pass}"
  }

  mongo_uri = { for db in ["sync_roadmap", "sync_exercise", "sync_nutrition", "sync_marketplace", "sync_social", "sync_notification"] :
    db => "mongodb://${module.mongo.username}:${module.mongo.password}@${module.mongo.private_ip}:27017/${db}?authSource=admin"
  }

  managed_secrets = merge(
    {
      "db/pg-iam"         = local.pg_conn["sync_iam"]
      "db/pg-order"       = local.pg_conn["sync_order"]
      "db/pg-payment"     = local.pg_conn["sync_payment"]
      "db/pg-smartpush"   = local.pg_conn["sync_smartpush"]
      "db/pg-ai-dsn"      = "postgresql://${local.pg_user}:${local.pg_pass}@${local.pg_host}:5432/sync_ai"
      "db/pg-aiagent-dsn" = "postgresql+asyncpg://${local.pg_user}:${local.pg_pass}@${local.pg_host}:5432/sync_ai_agent"
      "mq/amqp-url"       = module.mq.amqp_url
    },
    { for db, uri in local.mongo_uri : "db/mongo-${replace(db, "sync_", "")}" => uri },
  )

  # Secret user tự điền giá trị (aws secretsmanager put-secret-value)
  shell_secrets = [
    "shared/jwt-secret",
    "shared/internal-api-key",
    "llm/openai-api-key",
    "llm/deepseek-api-key",
    "llm/tavily-api-key",
    "pay/payos-client-id",
    "pay/payos-api-key",
    "pay/payos-checksum-key",
    "delivery/ahamove-api-key",
    "delivery/ahamove-mobile",
    "mail/brevo-username",
    "mail/brevo-password",
    "auth/google-client-ids",
    "ai/langfuse-public-key",
    "ai/langfuse-secret-key",
    "web/aws-map-api-key",
  ]
}

module "secrets" {
  source               = "../secrets"
  env                  = var.env
  region               = var.region
  shell_secrets        = local.shell_secrets
  managed_secrets      = local.managed_secrets
  recovery_window_days = var.secrets_recovery_window_days
}

module "iam_tasks" {
  source             = "../iam-tasks"
  name               = local.name
  env                = var.env
  region             = var.region
  secrets_prefix_arn = module.secrets.secret_prefix_arn
  s3_bucket_arns     = [module.s3_cdn.public_bucket_arn, module.s3_cdn.private_bucket_arn]
}

module "observability" {
  source                  = "../observability"
  name                    = local.name
  alert_email             = var.alert_email
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_blue_arn_suffix
  rds_identifier          = module.rds.instance_identifier
  mq_broker_name          = "${local.name}-rabbitmq"
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
