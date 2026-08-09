# 1 ALB public duy nhất → Gateway. HTTP :80 (chưa có domain); truyền
# certificate_arn để bật HTTPS :443. idle_timeout=300 cho SSE AI;
# deregistration_delay=60 cho SignalR drain. enable_bluegreen tạo thêm
# target group green + test listener :8081 cho CodeDeploy.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "name" { type = string } # vd sync-dev
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "certificate_arn" {
  type    = string
  default = "" # ARN ACM (có thể “known after apply” khi cert từ module.dns)
}
variable "enable_https" {
  # Plan-time known: do not derive solely from certificate_arn when ARN is unknown until apply.
  type    = bool
  default = false
}
variable "enable_bluegreen" {
  type    = bool
  default = false
}
variable "health_path" {
  type    = string
  default = "/health"
}

locals {
  https = var.enable_https
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Public ALB"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  dynamic "ingress" {
    for_each = local.https ? [1] : []
    content {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # Test listener blue/green — chỉ trong VPC (CodeDeploy validate)
  dynamic "ingress" {
    for_each = var.enable_bluegreen ? [1] : []
    content {
      description = "BlueGreen test listener (VPC only)"
      from_port   = 8081
      to_port     = 8081
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  ip_address_type    = "dualstack" # matches Route53 AAAA aliases for api.*
  idle_timeout       = 300         # SSE AI stream không đứt giữa chừng
}

# target_type=instance vì task bridge mode đăng ký <instance>:<dynamic-port>
resource "aws_lb_target_group" "blue" {
  name                 = "${var.name}-gw-blue"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 60

  health_check {
    path                = var.health_path
    interval            = 15
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "green" {
  count                = var.enable_bluegreen ? 1 : 0
  name                 = "${var.name}-gw-green"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 60

  health_check {
    path                = var.health_path
    interval            = 15
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

# :80 forward (no cert) — CodeDeploy có thể hoán TG → ignore default_action
resource "aws_lb_listener" "http" {
  count             = local.https ? 0 : 1
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

# :80 → 443 khi có certificate_arn (manual ACM ALB)
resource "aws_lb_listener" "http_redirect" {
  count             = local.https ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = local.https ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "test" {
  count             = var.enable_bluegreen ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 8081
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green[0].arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

output "alb_arn" { value = aws_lb.this.arn }
output "alb_dns_name" { value = aws_lb.this.dns_name }
output "alb_zone_id" { value = aws_lb.this.zone_id }
output "alb_arn_suffix" { value = aws_lb.this.arn_suffix }
output "security_group_id" { value = aws_security_group.alb.id }
output "target_group_blue_arn" { value = aws_lb_target_group.blue.arn }
output "target_group_blue_name" { value = aws_lb_target_group.blue.name }
output "target_group_blue_arn_suffix" { value = aws_lb_target_group.blue.arn_suffix }
output "target_group_green_arn" { value = var.enable_bluegreen ? aws_lb_target_group.green[0].arn : null }
output "target_group_green_name" { value = var.enable_bluegreen ? aws_lb_target_group.green[0].name : null }
output "prod_listener_arn" { value = local.https ? aws_lb_listener.https[0].arn : aws_lb_listener.http[0].arn }
output "test_listener_arn" { value = var.enable_bluegreen ? aws_lb_listener.test[0].arn : null }
