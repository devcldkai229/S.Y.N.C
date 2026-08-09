# Outputs khớp GitHub Actions vars (app-cicd.yml) + vận hành.

output "cluster_name" {
  description = "→ GitHub vars ECS_CLUSTER_DEV / ECS_CLUSTER_PROD"
  value       = module.ecs_cluster.cluster_name
}

output "alb_dns_name" {
  description = "→ GitHub vars SYNC_PUBLIC_URL_DEV/PROD (http(s)://api.<domain> hoặc ALB DNS)"
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
output "ai_sqs_queue_url" { value = module.sqs.queue_url }
output "mongo_private_ip" { value = module.mongo.private_ip }
output "cdn_domain" { value = module.s3_cdn.cdn_domain }
output "cdn_distribution_id" { value = module.s3_cdn.distribution_id }
output "public_bucket" { value = module.s3_cdn.public_bucket }
output "private_bucket" { value = module.s3_cdn.private_bucket }
output "sns_alerts_topic" { value = module.observability.sns_topic_arn }

output "web_bucket" {
  description = "→ GitHub vars WEB_BUCKET_DEV / WEB_BUCKET_PROD"
  value       = module.web_static.bucket_name
}

output "web_distribution_id" {
  description = "→ GitHub vars WEB_DISTRIBUTION_ID_DEV / WEB_DISTRIBUTION_ID_PROD"
  value       = module.web_static.distribution_id
}

output "web_url" {
  description = "URL site (custom domain hoặc *.cloudfront.net)"
  value       = local.enable_dns ? "https://${local.domain}" : "https://${module.web_static.distribution_domain}"
}

output "api_url" {
  description = "API base URL cho SYNC_PUBLIC_URL_* / NEXT_PUBLIC_API_URL"
  value       = local.api_base_url
}

output "cdn_url" {
  description = "Media CDN base URL (null when enable_media_cdn=false — use api_url/api/v1/media)"
  value       = local.enable_media_cdn ? (local.enable_dns ? "https://cdn.${local.domain}" : (module.s3_cdn.cdn_domain != null ? "https://${module.s3_cdn.cdn_domain}" : null)) : null
}

output "media_public_base_url" {
  description = "Storage__PublicBaseUrl injected into ECS (Gateway proxy or CDN)"
  value       = local.media_public_base_url
}

output "dns_name_servers" {
  description = "NS để trỏ tại registrar khi create_hosted_zone=true"
  value       = local.enable_dns ? module.dns[0].name_servers : null
}

output "secret_names" {
  description = "Secret cần put-secret-value trong Secrets Manager (giá trị đang CHANGE_ME)"
  value       = [for s in local.shell_secrets : "/sync/${var.env}/${s}"]
}

output "ssm_param_names" {
  description = "SSM param config thường cần put-parameter (giá trị đang CHANGE_ME)"
  value       = module.secrets.ssm_shell_param_names
}
