# SQS thay Amazon MQ (RabbitMQ) — hàng đợi AI intervention sync.ai.interventions.
# Rẻ hơn nhiều: SQS tính theo request (gần như $0 ở tải hiện tại) thay vì
# broker chạy 24/7. Consumer long-poll; message lỗi rơi vào DLQ (redrive).

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "name" { type = string } # vd sync-prod
variable "max_receive_count" {
  description = "Số lần nhận tối đa trước khi chuyển sang DLQ"
  type        = number
  default     = 5
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-ai-interventions-dlq"
  message_retention_seconds = 1209600 # 14 ngày
}

resource "aws_sqs_queue" "this" {
  name                       = "${var.name}-ai-interventions"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600 # 4 ngày
  receive_wait_time_seconds  = 20     # long-poll

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

output "queue_url" { value = aws_sqs_queue.this.url }
output "queue_arn" { value = aws_sqs_queue.this.arn }
output "queue_name" { value = aws_sqs_queue.this.name }
output "dlq_arn" { value = aws_sqs_queue.dlq.arn }
output "dlq_url" { value = aws_sqs_queue.dlq.url }
