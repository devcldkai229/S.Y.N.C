# PROD: NAT Gateway, RDS Single-AZ db.t4g.micro + deletion protection, SQS (thay MQ),
# critical on-demand >=2 task, rolling Gateway (KHÔNG blue/green — Service Connect),
# VPC endpoints (ECR only). DNS/web: domain_name + enable_dns via tfvars.

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "state_bucket" {
  description = "TF state bucket (must match backend.tf), used to read shared remote state"
  type        = string
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "certificate_arn" {
  description = "Optional ACM ap-southeast-1 ARN for ALB HTTPS (manual; dns module does not create ALB certs)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Apex domain for Route53 + CloudFront aliases (e.g. sync.vn)"
  type        = string
  default     = ""
}

variable "enable_dns" {
  description = "Enable Route53 records + CloudFront ACM (us-east-1). Requires domain_name."
  type        = bool
  default     = false
}

variable "create_hosted_zone" {
  description = "Create a new public hosted zone; set false to use an existing zone"
  type        = bool
  default     = false
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      project    = "sync"
      env        = "prod"
      managed-by = "terraform"
    }
  }
}

# Required by module.stack -> module.dns (CloudFront ACM must be in us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      project    = "sync"
      env        = "prod"
      managed-by = "terraform"
    }
  }
}

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "shared/terraform.tfstate"
    region = var.region
  }
}

module "stack" {
  source = "../../modules/stack"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  env                 = "prod"
  region              = var.region
  ecr_repository_urls = data.terraform_remote_state.shared.outputs.ecr_repository_urls

  # Capacity: spot must fit ~10 non-critical tasks (cpu/mem). t4g.medium ≈ 2 vCPU/4 GiB → need 2 nodes.
  instance_type = "t4g.medium"
  ondemand      = { min = 1, max = 4, desired = 2 }
  spot          = { min = 2, max = 4, desired = 2 }

  # Cắt chi phí: db.t4g.micro + Single-AZ (giữ deletion_protection).
  # ⚠️ 1 GB RAM cho nhiều DB + pgvector, không auto-failover — theo dõi CPU/RAM.
  rds_instance_class      = "db.t4g.micro"
  rds_multi_az            = false
  rds_deletion_protection = true
  rds_skip_final_snapshot = false
  # MongoDB self-host: t4g.small (2 GB) — micro (1 GB) thiếu headroom cho multi-DB WiredTiger.
  mongo_instance_type = "t4g.small"

  # NAT instance (t4g.nano) replaces managed NAT Gateway (~$30/mo). SPOF for all private
  # outbound (OpenAI, PayOS, Brevo, Google Play verify) — switch back to "gateway" under traffic.
  # ECR image layers use free S3 gateway endpoint; interface ECR API endpoints disabled (~$15/mo).
  vpc_cidr                   = "10.30.0.0/16"
  nat_mode                   = "instance"
  enable_interface_endpoints = false

  # Gateway dùng ROLLING (circuit breaker + auto rollback) — KHÔNG blue/green.
  # Lý do: gateway cần ECS Service Connect (client) để gọi backend qua DNS nội bộ,
  # mà Service Connect KHÔNG hỗ trợ deployment type blue/green (CODE_DEPLOY) →
  # bật blue/green sẽ hỏng gateway. Muốn blue/green thật: chuyển gateway sang
  # network_mode=awsvpc + target_type=ip + bỏ Service Connect ở gateway (thay bằng
  # gọi backend qua ALB nội bộ), rồi mới set true. Xem docs/deploy checklist.
  enable_bluegreen   = false
  enable_media_cdn   = true
  certificate_arn    = var.certificate_arn
  domain_name        = var.domain_name
  enable_dns         = var.enable_dns
  create_hosted_zone = var.create_hosted_zone

  jwt_issuer   = "sync-lifestyle-iam"
  jwt_audience = "sync-lifestyle-clients"

  desired_count_critical       = 2
  log_retention_days           = 30
  secrets_recovery_window_days = 7
  alert_email                  = var.alert_email
}

output "cluster_name" { value = module.stack.cluster_name }
output "alb_dns_name" { value = module.stack.alb_dns_name }
output "migrate_subnets" { value = module.stack.migrate_subnets }
output "migrate_security_group" { value = module.stack.migrate_security_group }
output "rds_endpoint" { value = module.stack.rds_endpoint }
output "redis_endpoint" { value = module.stack.redis_endpoint }
output "ai_sqs_queue_url" { value = module.stack.ai_sqs_queue_url }
output "mongo_private_ip" { value = module.stack.mongo_private_ip }
output "cdn_domain" { value = module.stack.cdn_domain }
output "cdn_url" { value = module.stack.cdn_url }
output "web_bucket" { value = module.stack.web_bucket }
output "web_distribution_id" { value = module.stack.web_distribution_id }
output "web_url" { value = module.stack.web_url }
output "api_url" { value = module.stack.api_url }
output "dns_name_servers" { value = module.stack.dns_name_servers }
output "secret_names" { value = module.stack.secret_names }
output "ssm_param_names" { value = module.stack.ssm_param_names }
