# CodeDeploy blue/green cho Gateway (prod). Naming PHẢI khớp ecs-bluegreen.sh:
#   application = sync-prod-gateway ; deployment group = sync-prod-gateway-dg

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "name" { type = string } # sync-prod-gateway
variable "cluster_name" { type = string }
variable "service_name" { type = string }
variable "prod_listener_arn" { type = string }
variable "test_listener_arn" { type = string }
variable "target_group_blue_name" { type = string }
variable "target_group_green_name" { type = string }

data "aws_iam_policy_document" "assume_codedeploy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "${var.name}-codedeploy"
  assume_role_policy = data.aws_iam_policy_document.assume_codedeploy.json
}

resource "aws_iam_role_policy_attachment" "codedeploy_ecs" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_codedeploy_app" "this" {
  name             = var.name
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name               = aws_codedeploy_app.this.name
  deployment_group_name  = "${var.name}-dg"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = var.service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.prod_listener_arn]
      }
      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }
      target_group {
        name = var.target_group_blue_name
      }
      target_group {
        name = var.target_group_green_name
      }
    }
  }
}

output "app_name" { value = aws_codedeploy_app.this.name }
output "deployment_group_name" { value = aws_codedeploy_deployment_group.this.deployment_group_name }
