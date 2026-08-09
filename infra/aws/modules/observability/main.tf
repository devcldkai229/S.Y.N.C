# Observability: SNS topic (email) + alarms nền tảng (ALB 5xx/unhealthy,
# RDS CPU/storage/conn). Log groups per-service nằm ở
# module ecs-service. Retention ngắn để rẻ.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "name" { type = string }
variable "alert_email" {
  type    = string
  default = "" # rỗng = không tạo subscription (confirm qua email khi điền)
}
variable "alb_arn_suffix" { type = string }
variable "target_group_arn_suffix" { type = string }
variable "rds_identifier" { type = string }

resource "aws_sns_topic" "alerts" {
  name = "${var.name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name}-alb-5xx"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 20
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
  alarm_actions       = local.actions
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "tg_unhealthy" {
  alarm_name          = "${var.name}-gateway-unhealthy"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
  alarm_actions      = local.actions
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.name}-rds-cpu"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  alarm_actions       = local.actions
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.name}-rds-storage-low"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2147483648 # 2 GiB
  comparison_operator = "LessThanThreshold"
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  alarm_actions       = local.actions
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.name}-rds-connections"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  alarm_actions       = local.actions
}

output "sns_topic_arn" { value = aws_sns_topic.alerts.arn }
