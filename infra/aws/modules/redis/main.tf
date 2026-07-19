# ElastiCache Redis 7 — cache + rate-limit + LangGraph checkpointer + SignalR
# backplane. Single node t4g.micro; transit encryption TẮT (client hiện nối
# không TLS — bật sau khi cập nhật conn string toàn bộ service).

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "allowed_security_group_ids" { type = list(string) }
variable "node_type" {
  type    = string
  default = "cache.t4g.micro"
}

resource "aws_elasticache_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "this" {
  name        = "${var.name}-redis"
  description = "Redis from ECS"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "Redis"
      from_port       = 6379
      to_port         = 6379
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

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.name}-redis"
  description          = "SYNC Redis (${var.name})"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  num_cache_clusters   = 1
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false # client chưa cấu hình TLS
  automatic_failover_enabled = false

  snapshot_retention_limit = 1
  maintenance_window       = "sun:19:00-sun:20:00" # ~02:00-03:00 VN
}

output "endpoint" { value = aws_elasticache_replication_group.this.primary_endpoint_address }
output "port" { value = 6379 }
output "security_group_id" { value = aws_security_group.this.id }
