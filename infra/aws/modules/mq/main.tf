# Amazon MQ RabbitMQ — message bus (AI consumer queue sync.ai.interventions).
# dev: SINGLE_INSTANCE mq.t3.micro · prod: ACTIVE_STANDBY_MULTI_AZ (var).
# Creds TF sinh (state encrypt) — amqps URL ghép ở env layer → Secrets Manager.

terraform {
  required_providers {
    aws    = { source = "hashicorp/aws" }
    random = { source = "hashicorp/random" }
  }
}

variable "name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "allowed_security_group_ids" { type = list(string) }
variable "deployment_mode" {
  type    = string
  default = "SINGLE_INSTANCE" # prod: ACTIVE_STANDBY_MULTI_AZ
}
variable "instance_type" {
  type    = string
  default = "mq.t3.micro"
}

resource "random_password" "mq" {
  length  = 24
  special = false # RabbitMQ/amqp URL an toàn khi không ký tự đặc biệt
}

resource "aws_security_group" "this" {
  name        = "${var.name}-mq"
  description = "RabbitMQ AMQPS from ECS"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "AMQPS"
      from_port       = 5671
      to_port         = 5671
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

resource "aws_mq_broker" "this" {
  broker_name        = "${var.name}-rabbitmq"
  engine_type        = "RabbitMQ"
  engine_version     = "3.13"
  host_instance_type = var.instance_type
  deployment_mode    = var.deployment_mode

  # SINGLE_INSTANCE: 1 subnet; ACTIVE_STANDBY: 2 subnet
  subnet_ids = var.deployment_mode == "SINGLE_INSTANCE" ? [var.private_subnet_ids[0]] : var.private_subnet_ids

  security_groups            = [aws_security_group.this.id]
  publicly_accessible        = false
  apply_immediately          = true
  auto_minor_version_upgrade = true

  user {
    username = "sync"
    password = random_password.mq.result
  }

  logs {
    general = true
  }

  maintenance_window_start_time {
    day_of_week = "SUNDAY"
    time_of_day = "19:00" # ~02:00 VN
    time_zone   = "UTC"
  }
}

locals {
  # endpoints[0] dạng amqps://b-xxxx.mq.<region>.amazonaws.com:5671
  amqp_endpoint = aws_mq_broker.this.instances[0].endpoints[0]
  amqp_url      = replace(local.amqp_endpoint, "amqps://", "amqps://sync:${random_password.mq.result}@")
}

output "amqp_url" {
  value     = local.amqp_url
  sensitive = true
}
output "console_url" { value = aws_mq_broker.this.instances[0].console_url }
output "security_group_id" { value = aws_security_group.this.id }
output "broker_id" { value = aws_mq_broker.this.id }
