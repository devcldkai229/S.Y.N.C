# DEV: rẻ tối đa — NAT instance, RDS single-AZ, MQ single, Spot nhiều.

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
  description = "Bucket state (trùng backend.tf) để đọc shared state"
  type        = string
}
variable "alert_email" {
  type    = string
  default = ""
}
variable "domain_name" {
  type    = string
  default = ""
}
variable "enable_dns" {
  type    = bool
  default = false
}
variable "create_hosted_zone" {
  type    = bool
  default = false
}
variable "certificate_arn" {
  description = "Optional ACM ap-southeast-1 ARN for ALB HTTPS (manual)"
  type        = string
  default     = ""
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      project    = "sync"
      env        = "dev"
      managed-by = "terraform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      project    = "sync"
      env        = "dev"
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

  env                 = "dev"
  region              = var.region
  ecr_repository_urls = data.terraform_remote_state.shared.outputs.ecr_repository_urls

  vpc_cidr                   = "10.20.0.0/16"
  nat_mode                   = "instance" # t4g.nano ~$4/mo
  enable_interface_endpoints = false      # dev đi qua NAT instance cho rẻ

  instance_type = "t4g.medium"
  ondemand      = { min = 1, max = 2, desired = 1 }
  spot          = { min = 1, max = 3, desired = 1 }

  rds_instance_class      = "db.t4g.small"
  rds_multi_az            = false
  rds_deletion_protection = false
  rds_skip_final_snapshot = true

  enable_bluegreen   = false
  enable_media_cdn   = false
  certificate_arn    = var.certificate_arn
  domain_name        = var.domain_name
  enable_dns         = var.enable_dns
  create_hosted_zone = var.create_hosted_zone

  jwt_issuer   = "sync-lifestyle-iam-dev"
  jwt_audience = "sync-lifestyle-clients-dev"

  desired_count_critical       = 1
  log_retention_days           = 14
  secrets_recovery_window_days = 0
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
