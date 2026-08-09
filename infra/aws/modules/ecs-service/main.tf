# ★ Module tái dùng cho 13 service: task def (container tên "app" — khớp
# ecs-deploy.sh/ecs-bluegreen.sh sửa containerDefinitions[0]) + ECS service
# (bridge + Service Connect) + autoscaling. Image được CI thay bằng tag SHA
# → lifecycle ignore task_definition/desired_count để TF không revert deploy.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "name" { type = string } # full: sync-dev-iam (khớp workflow)
variable "cluster_arn" { type = string }
variable "image" { type = string } # image khởi điểm (CI sẽ thay)
variable "cpu" {
  type    = number
  default = 256
}
variable "memory" {
  type    = number
  default = 512
}
variable "container_port" {
  description = "null cho worker (không listen)"
  type        = number
  default     = 8080
}
variable "service_alias" {
  description = "DNS Service Connect (vd iam → http://iam:8080). null = client-only"
  type        = string
  default     = null
}
variable "command" {
  type    = list(string)
  default = null
}
variable "desired_count" {
  type    = number
  default = 1
}
variable "autoscaling" {
  type    = object({ min = number, max = number, cpu_target = number })
  default = null
}
variable "capacity_provider" { type = string } # tên CP ondemand hoặc spot
variable "env" {
  type    = map(string)
  default = {}
}
variable "secrets" {
  description = "map ENV_NAME → secret ARN (ECS valueFrom)"
  type        = map(string)
  default     = {}
}
variable "task_role_arn" { type = string }
variable "execution_role_arn" { type = string }
variable "namespace_arn" { type = string }
variable "log_retention_days" {
  type    = number
  default = 14
}
variable "region" { type = string }
variable "deployment_controller" {
  type    = string
  default = "ECS" # ECS | CODE_DEPLOY (gateway prod blue/green)
}
variable "health_check_grace_period_seconds" {
  description = "Ân hạn health check ALB — đủ cho .NET khởi động + chạy EF migrations"
  type        = number
  default     = 180
}
variable "target_group_arn" {
  description = "Gắn ALB (gateway). null = không public"
  type        = string
  default     = null
}
variable "cluster_name" { type = string }

locals {
  is_worker = var.container_port == null
  has_sc    = var.service_alias != null && !local.is_worker
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "app" # PHẢI là "app" — ecs-bluegreen.sh CONTAINER_NAME mặc định
      image     = var.image
      essential = true
      command   = var.command
      portMappings = local.is_worker ? [] : [
        {
          name          = "app"
          containerPort = var.container_port
          hostPort      = 0 # dynamic — bin-packing bridge mode
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      environment = [for k, v in var.env : { name = k, value = v }]
      secrets     = [for k, a in var.secrets : { name = k, valueFrom = a }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight            = 1
  }

  # Service .NET tự chạy Database.MigrateAsync() lúc khởi động → cần thời gian ân
  # hạn trước khi ALB đánh unhealthy, nếu không sẽ crash-loop vô hạn.
  # Chỉ hợp lệ khi service có load balancer.
  health_check_grace_period_seconds = var.target_group_arn != null ? var.health_check_grace_period_seconds : null

  # Cluster nhỏ (1–2 instance t4g, binpack): với desired_count=1 mà giữ mặc định
  # min=100% thì ECS phải chen task mới trước khi tắt task cũ → dễ treo vì hết RAM.
  # (Không áp dụng cho CODE_DEPLOY — blue/green tự quản.)
  deployment_minimum_healthy_percent = var.deployment_controller == "ECS" ? (var.desired_count >= 2 ? 50 : 0) : null
  deployment_maximum_percent         = var.deployment_controller == "ECS" ? 200 : null

  deployment_controller {
    type = var.deployment_controller
  }

  # Circuit breaker chỉ hợp lệ với controller ECS (rolling)
  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_controller == "ECS" ? [1] : []
    content {
      enable   = true
      rollback = true
    }
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = "app"
      container_port   = var.container_port
    }
  }

  service_connect_configuration {
    enabled   = true
    namespace = var.namespace_arn

    dynamic "service" {
      for_each = local.has_sc ? [1] : []
      content {
        port_name      = "app"
        discovery_name = var.service_alias
        client_alias {
          port     = var.container_port
          dns_name = var.service_alias
        }
      }
    }
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  # CI đăng ký revision mới + autoscaling đổi desired → TF không ghi đè.
  # load_balancer: CodeDeploy blue/green hoán đổi target group trên service —
  # nếu không ignore, `terraform apply` kế tiếp sẽ revert về TG blue và phá deploy.
  lifecycle {
    ignore_changes = [task_definition, desired_count, load_balancer]
  }
}

resource "aws_appautoscaling_target" "this" {
  count              = var.autoscaling != null ? 1 : 0
  max_capacity       = var.autoscaling.max
  min_capacity       = var.autoscaling.min
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count              = var.autoscaling != null ? 1 : 0
  name               = "${var.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.autoscaling.cpu_target
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

output "service_name" { value = aws_ecs_service.this.name }
output "task_definition_arn" { value = aws_ecs_task_definition.this.arn }
output "log_group" { value = aws_cloudwatch_log_group.this.name }
