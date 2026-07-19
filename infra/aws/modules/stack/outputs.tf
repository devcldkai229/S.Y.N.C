# Outputs khớp GitHub Actions vars (app-cicd.yml) + vận hành.

output "cluster_name" {
  description = "→ GitHub vars ECS_CLUSTER_DEV / ECS_CLUSTER_PROD"
  value       = module.ecs_cluster.cluster_name
}

output "alb_dns_name" {
  description = "→ GitHub vars SYNC_PUBLIC_URL_DEV/PROD (http://<dns>)"
  value       = module.alb.alb_dns_name
}

output "migrate_subnets" {
  description = "→ GitHub var MIGRATE_SUBNETS (dạng subnet-a,subnet-b)"
  value       = join(",", module.network.private_subnet_ids)
}

output "migrate_security_group" {
  description = "→ GitHub var MIGRATE_SG"
  value       = module.ecs_cluster.instances_security_group_id
}

output "rds_endpoint" { value = module.rds.endpoint }
output "redis_endpoint" { value = module.redis.endpoint }
output "mq_console_url" { value = module.mq.console_url }
output "mongo_private_ip" { value = module.mongo.private_ip }
output "cdn_domain" { value = module.s3_cdn.cdn_domain }
output "public_bucket" { value = module.s3_cdn.public_bucket }
output "private_bucket" { value = module.s3_cdn.private_bucket }
output "sns_alerts_topic" { value = module.observability.sns_topic_arn }

output "secret_names" {
  description = "Danh sách secret user cần put-secret-value (giá trị đang CHANGE_ME)"
  value       = [for s in local.shell_secrets : "/sync/${var.env}/${s}"]
}
