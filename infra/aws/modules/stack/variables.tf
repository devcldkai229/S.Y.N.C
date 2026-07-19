variable "env" { type = string } # dev | prod
variable "region" { type = string }

# Từ envs/shared (remote state)
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
  type    = object({ min = number, max = number, desired = number })
  default = { min = 1, max = 3, desired = 1 }
}
variable "spot" {
  type    = object({ min = number, max = number, desired = number })
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
variable "mq_deployment_mode" {
  type    = string
  default = "SINGLE_INSTANCE"
}
variable "mongo_instance_type" {
  type    = string
  default = "t4g.small"
}

# Ingress
variable "certificate_arn" {
  type    = string
  default = "" # điền ACM ARN khi có domain → bật HTTPS
}
variable "enable_bluegreen" {
  type    = bool
  default = false # prod: true (CodeDeploy gateway)
}

# App
variable "jwt_issuer" { type = string }
variable "jwt_audience" { type = string }
variable "critical_services" {
  description = "Service chạy on-demand (còn lại Spot)"
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
  description = "Tag khởi điểm cho task def (CI thay bằng SHA)"
  type        = string
  default     = "bootstrap"
}
