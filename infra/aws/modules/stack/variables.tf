variable "env" { type = string } # dev | prod
variable "region" { type = string }

# Public DNS / web (indexed early for editor / terraform-ls)
variable "domain_name" {
  description = "Apex domain (e.g. sync.vn). Empty with enable_dns=false skips Route53/ACM"
  type        = string
  default     = ""
}
variable "enable_dns" {
  description = "When true and domain_name set: Route53 + CloudFront ACM (us-east-1)"
  type        = bool
  default     = false
}
variable "create_hosted_zone" {
  description = "true = create Route53 zone; false = use existing public zone (data source)"
  type        = bool
  default     = false
}

# From envs/shared remote state
variable "ecr_repository_urls" { type = map(string) }

# Network
variable "vpc_cidr" { type = string }
variable "nat_mode" { type = string }
variable "enable_interface_endpoints" {
  type    = bool
  default = false
}

# Compute
variable "instance_type" {
  type    = string
  default = "t4g.medium"
}
variable "ondemand" {
  type = object({
    min     = number
    max     = number
    desired = number
  })
  default = { min = 1, max = 3, desired = 1 }
}
variable "spot" {
  type = object({
    min     = number
    max     = number
    desired = number
  })
  default = { min = 0, max = 4, desired = 1 }
}

# Data stores
variable "rds_instance_class" {
  type    = string
  default = "db.t4g.small"
}
variable "rds_multi_az" {
  type    = bool
  default = false
}
variable "rds_deletion_protection" {
  type    = bool
  default = false
}
variable "rds_skip_final_snapshot" {
  type    = bool
  default = true
}
variable "mongo_instance_type" {
  type    = string
  default = "t4g.small"
}

# Ingress
variable "certificate_arn" {
  description = "Manual ACM ARN in ap-southeast-1 for ALB HTTPS (dns module does not create ALB certs)"
  type        = string
  default     = ""
}
variable "enable_bluegreen" {
  type    = bool
  default = false # prod: true (CodeDeploy gateway)
}
variable "enable_media_cdn" {
  description = "CloudFront + bucket policy on sync-pub-assets. false on dev (shared bucket; media via Gateway)."
  type        = bool
  default     = false
}

# App
variable "jwt_issuer" { type = string }
variable "jwt_audience" { type = string }
variable "critical_services" {
  description = "Services pinned to on-demand capacity (others prefer Spot)"
  type        = list(string)
  default     = ["gateway", "iam", "payment"]
}
variable "desired_count_critical" {
  type    = number
  default = 1
}
variable "log_retention_days" {
  type    = number
  default = 14
}
variable "secrets_recovery_window_days" {
  type    = number
  default = 0
}
variable "alert_email" {
  type    = string
  default = ""
}
variable "image_tag" {
  description = "Bootstrap image tag for task definitions (CI replaces with SHA)"
  type        = string
  default     = "bootstrap"
}
