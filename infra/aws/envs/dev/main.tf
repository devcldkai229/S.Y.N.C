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
  mq_deployment_mode      = "SINGLE_INSTANCE"

  enable_bluegreen = false
  certificate_arn  = ""

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
output "mq_console_url" { value = module.stack.mq_console_url }
output "mongo_private_ip" { value = module.stack.mongo_private_ip }
output "cdn_domain" { value = module.stack.cdn_domain }
output "secret_names" { value = module.stack.secret_names }
