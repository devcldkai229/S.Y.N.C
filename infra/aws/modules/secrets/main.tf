# Secrets & config:
#   - shell_secrets    : CHỈ tạo vỏ Secrets Manager — GIÁ TRỊ do người vận hành
#                        `aws secretsmanager put-secret-value` (không nằm trong TF state).
#   - managed_secrets  : secret hạ tầng TF tự sinh (db password) — giá trị CÓ trong
#                        state (state bucket đã encrypt + private).
#   - ssm_params       : config thường TF biết giá trị (db host/port/user) → SSM (free).
#   - ssm_shell_params : config thường do người vận hành điền → SSM placeholder
#                        `aws ssm put-parameter --overwrite` (ignore_changes giữ giá trị).

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "env" { type = string } # dev | prod
variable "region" { type = string }
variable "shell_secrets" {
  description = "Danh sách path secret user tự điền, vd shared/jwt-secret"
  type        = list(string)
}
variable "managed_secrets" {
  description = "map path→value do TF quản trị giá trị"
  type        = map(string)
  default     = {}
  sensitive   = true
}
variable "ssm_params" {
  description = "map path→value config thường (TF biết giá trị)"
  type        = map(string)
  default     = {}
}
variable "ssm_shell_params" {
  description = "Danh sách path config thường do người vận hành điền (placeholder CHANGE_ME)"
  type        = list(string)
  default     = []
}
variable "recovery_window_days" {
  type    = number
  default = 0 # dev: xoá ngay để re-apply dễ; prod nên 7
}

data "aws_caller_identity" "current" {}

locals {
  prefix = "/sync/${var.env}"
}

resource "aws_secretsmanager_secret" "shell" {
  for_each                = toset(var.shell_secrets)
  name                    = "${local.prefix}/${each.value}"
  recovery_window_in_days = var.recovery_window_days
}

# Vỏ có version placeholder để ECS không fail khi user chưa kịp điền —
# ignore_changes để giá trị thật user put không bị TF ghi đè.
resource "aws_secretsmanager_secret_version" "shell_placeholder" {
  for_each      = aws_secretsmanager_secret.shell
  secret_id     = each.value.id
  secret_string = "CHANGE_ME"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# for_each không nhận map sensitive → duyệt theo KEYS (tên secret không nhạy cảm);
# giá trị tra cứu qua var (vẫn sensitive, provider ẩn trong plan).
locals {
  managed_keys = nonsensitive(toset(keys(var.managed_secrets)))
}

resource "aws_secretsmanager_secret" "managed" {
  for_each                = local.managed_keys
  name                    = "${local.prefix}/${each.value}"
  recovery_window_in_days = var.recovery_window_days
}

resource "aws_secretsmanager_secret_version" "managed" {
  for_each      = local.managed_keys
  secret_id     = aws_secretsmanager_secret.managed[each.value].id
  secret_string = var.managed_secrets[each.value]
}

resource "aws_ssm_parameter" "this" {
  for_each = var.ssm_params
  name     = "${local.prefix}/${each.key}"
  type     = "String"
  value    = each.value
}

# Placeholder cho config người vận hành điền — ignore_changes để không ghi đè.
resource "aws_ssm_parameter" "shell" {
  for_each = toset(var.ssm_shell_params)
  name     = "${local.prefix}/${each.value}"
  type     = "String"
  value    = "CHANGE_ME"

  lifecycle {
    ignore_changes = [value]
  }
}

output "secret_arns" {
  description = "map path→ARN (cả shell lẫn managed)"
  value = merge(
    { for k, s in aws_secretsmanager_secret.shell : k => s.arn },
    { for k, s in aws_secretsmanager_secret.managed : k => s.arn },
  )
}
output "secret_prefix_arn" {
  value = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${local.prefix}/*"
}
output "param_arns" {
  description = "map path→ARN (cả ssm_params lẫn ssm_shell_params)"
  value = merge(
    { for k, p in aws_ssm_parameter.this : k => p.arn },
    { for k, p in aws_ssm_parameter.shell : k => p.arn },
  )
}
output "ssm_shell_param_names" {
  value = [for s in var.ssm_shell_params : "${local.prefix}/${s}"]
}
