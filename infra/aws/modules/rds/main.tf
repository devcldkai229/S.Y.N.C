# RDS PostgreSQL 17 Graviton — 1 instance gộp mọi DB quan hệ + pgvector:
#   sync_iam, sync_order, sync_payment, sync_smartpush, sync_ai, sync_ai_agent
# (database + CREATE EXTENSION vector chạy bằng init SQL one-off — xem README).
# Master password do TF sinh (nằm trong state — state bucket encrypt+private).

terraform {
  required_providers {
    aws    = { source = "hashicorp/aws" }
    random = { source = "hashicorp/random" }
  }
}

variable "name" { type = string } # vd sync-dev
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "allowed_security_group_ids" { type = list(string) }
variable "instance_class" {
  type    = string
  default = "db.t4g.small"
}
variable "multi_az" {
  type    = bool
  default = false
}
variable "allocated_storage" {
  type    = number
  default = 20
}
variable "deletion_protection" {
  type    = bool
  default = false
}
variable "skip_final_snapshot" {
  type    = bool
  default = true
}

resource "random_password" "master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+" # RDS cấm / @ " space
}

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "this" {
  name        = "${var.name}-rds"
  description = "PostgreSQL from ECS"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "PostgreSQL"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name}-postgres"
  engine         = "postgres"
  engine_version = "17"

  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 5
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "postgres"
  username = "sync_admin"
  password = random_password.master.result

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false

  backup_retention_period    = 7
  auto_minor_version_upgrade = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : "${var.name}-postgres-final"

  performance_insights_enabled = false # bật khi cần soi query (tốn phí ở t4g nhỏ)

  lifecycle {
    ignore_changes = [engine_version] # minor auto-upgrade không gây diff
  }
}

output "endpoint" { value = aws_db_instance.this.address }
output "port" { value = aws_db_instance.this.port }
output "username" { value = aws_db_instance.this.username }
output "password" {
  value     = random_password.master.result
  sensitive = true
}
output "security_group_id" { value = aws_security_group.this.id }
output "instance_arn" { value = aws_db_instance.this.arn }
output "instance_identifier" { value = aws_db_instance.this.identifier }
