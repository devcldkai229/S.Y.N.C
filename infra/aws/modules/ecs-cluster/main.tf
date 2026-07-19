# ECS cluster trên EC2 Graviton (t4g) + Spot, bin-packing.
# LƯU Ý KIẾN TRÚC: t4g KHÔNG hỗ trợ ENI trunking → nếu dùng awsvpc mỗi task
# chiếm 1 ENI (t4g.medium chỉ ~2 task/instance). Vì vậy task app dùng
# network_mode=bridge + dynamic host port + ECS Service Connect (hỗ trợ bridge)
# để nhồi ~13 container lên 1–2 instance đúng thiết kế chi phí.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "name" { type = string } # vd sync-dev — PHẢI khớp vars.ECS_CLUSTER_* của GitHub
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }
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
variable "namespace_name" { type = string } # vd sync-dev.local

data "aws_ssm_parameter" "ecs_ami_arm" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id"
}

# ── Service Connect namespace ────────────────────────────────────────────────
resource "aws_service_discovery_http_namespace" "this" {
  name        = var.namespace_name
  description = "ECS Service Connect namespace for ${var.name}"
}

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "disabled" # bật "enabled" khi cần soi sâu (tốn phí CW)
  }

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.this.arn
  }
}

# ── SG cho ECS instances ─────────────────────────────────────────────────────
resource "aws_security_group" "instances" {
  name        = "${var.name}-ecs-instances"
  description = "ECS container instances"
  vpc_id      = var.vpc_id

  # Bridge mode dynamic ports: ALB → instance ephemeral range
  ingress {
    description     = "ALB to dynamic host ports"
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }
  # Service Connect proxy + inter-task trên các instance
  ingress {
    description = "Self all (Service Connect / inter-task)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── Instance role ────────────────────────────────────────────────────────────
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${var.name}-ecs-instance"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_role_policy_attachment" "instance_ecs" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "instance_ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.name}-ecs-instance"
  role = aws_iam_role.instance.name
}

# ── Launch templates (on-demand + spot) ─────────────────────────────────────
locals {
  user_data = base64encode(<<-EOF
    #!/bin/bash
    cat >> /etc/ecs/ecs.config <<'CFG'
    ECS_CLUSTER=${var.name}
    ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
    ECS_CONTAINER_STOP_TIMEOUT=60s
    CFG
  EOF
  )
  pools = {
    ondemand = { spot = false, cfg = var.ondemand, weight = 1, base = 1 }
    spot     = { spot = true, cfg = var.spot, weight = 4, base = 0 }
  }
}

resource "aws_launch_template" "this" {
  for_each      = local.pools
  name_prefix   = "${var.name}-${each.key}-"
  image_id      = data.aws_ssm_parameter.ecs_ami_arm.value
  instance_type = var.instance_type
  user_data     = local.user_data

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance.arn
  }

  vpc_security_group_ids = [aws_security_group.instances.id]

  dynamic "instance_market_options" {
    for_each = each.value.spot ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        spot_instance_type = "one-time"
      }
    }
  }

  metadata_options {
    http_tokens   = "required" # IMDSv2
    http_endpoint = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 40
      volume_type = "gp3"
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name}-ecs-${each.key}" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  for_each            = local.pools
  name                = "${var.name}-ecs-${each.key}"
  min_size            = each.value.cfg.min
  max_size            = each.value.cfg.max
  desired_capacity    = each.value.cfg.desired
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.this[each.key].id
    version = "$Latest"
  }

  # Capacity provider managed scaling điều khiển desired → bỏ qua drift
  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "this" {
  for_each = local.pools
  name     = "${var.name}-${each.key}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.this[each.key].arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 90 # chừa ~10% headroom cho deploy surge
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [for cp in aws_ecs_capacity_provider.this : cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this["ondemand"].name
    base              = 1
    weight            = 1
  }
}

output "cluster_name" { value = aws_ecs_cluster.this.name }
output "cluster_arn" { value = aws_ecs_cluster.this.arn }
output "instances_security_group_id" { value = aws_security_group.instances.id }
output "namespace_arn" { value = aws_service_discovery_http_namespace.this.arn }
output "capacity_provider_ondemand" { value = aws_ecs_capacity_provider.this["ondemand"].name }
output "capacity_provider_spot" { value = aws_ecs_capacity_provider.this["spot"].name }
