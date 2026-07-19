# SYNC — Terraform AWS

Hạ tầng theo kiến trúc đã chốt: **ECS on EC2 Graviton (t4g) + Spot bin-packing**,
1 ALB (Gateway) + ECS **Service Connect** nội bộ, RDS PostgreSQL 17 (+pgvector, gộp
mọi DB quan hệ), ElastiCache Redis, Amazon MQ RabbitMQ, **MongoDB self-host EC2**
(+EBS +DLM snapshot), S3 + CloudFront thay MinIO. 2 môi trường **dev + prod**.

> **Quyết định kỹ thuật quan trọng:** t4g **không hỗ trợ ENI trunking** nên task app
> dùng `network_mode=bridge` + dynamic host port + Service Connect (thay vì awsvpc —
> awsvpc chỉ nhồi được ~2 task/instance t4g, phá vỡ bài toán bin-packing chi phí).

## Cấu trúc

```
bootstrap/          # 1 lần: S3 state bucket + DynamoDB lock (state local)
modules/
  network ecr iam-cicd iam-tasks secrets ecs-cluster ecs-service
  alb codedeploy-ecs rds redis mq mongo-ec2 s3-cdn observability
  stack/            # composite per-env: wiring toàn bộ + map 13 service
envs/
  shared/           # ECR 12 repo + GitHub OIDC roles (dùng chung dev+prod) — apply TRƯỚC
  dev/              # NAT instance, single-AZ, Spot nhiều
  prod/             # NAT GW, RDS Multi-AZ, MQ active-standby, blue/green Gateway
```

## Thứ tự bring-up

```bash
# 0. Bootstrap state (local state, 1 lần)
cd infra/aws/bootstrap && terraform init && terraform apply
# → ghi lại output state_bucket (sync-tfstate-<account_id>)

# 1. Điền account id vào backend.tf của shared/dev/prod (REPLACE_ACCOUNT_ID)
#    + copy terraform.tfvars.example → terraform.tfvars ở cả 3 env

# 2. Shared (ECR + OIDC roles)
cd ../envs/shared && terraform init && terraform apply
# → outputs: deploy_role_arn (GitHub secret AWS_OIDC_ROLE_ARN),
#            infra_role_arn  (GitHub secret AWS_OIDC_ROLE_ARN_INFRA)

# 3. Dev
cd ../dev && terraform init && terraform apply
# → outputs: cluster_name, alb_dns_name, migrate_subnets, migrate_security_group
#   (điền vào GitHub Variables — xem docs/deploy/SYNC-AWS-Production-Setup-Checklist.md)

# 4. Điền secrets (đang là CHANGE_ME) — danh sách ở output secret_names:
aws secretsmanager put-secret-value \
  --secret-id /sync/dev/shared/jwt-secret --secret-string '<value>'
# ... lặp cho từng secret (xem checklist)

# 5. Init database trên RDS (tạo DB + pgvector — 1 lần):
#    chạy scripts/init-databases.sql qua bastion/SSM port-forward tới RDS
#    (mẫu port-forward trong checklist).

# 6. Push image lần đầu (tag bootstrap) để service có image chạy:
#    xem lệnh trong checklist §"Image bootstrap" — hoặc merge main để CI push tag SHA
#    rồi pipeline tự deploy.

# 7. Prod: lặp bước 3-6 với envs/prod (có manual approval qua infra.yml).
```

## Secrets — quy ước

| Loại | Nơi chứa | Ai điền |
|---|---|---|
| Credential app (JWT, InternalApiKey, PayOS, Ahamove, Brevo, OpenAI/DeepSeek/Tavily, Langfuse, Google, AWS Map key) | Secrets Manager `/sync/<env>/...` (vỏ tạo sẵn, giá trị `CHANGE_ME`) | **Người vận hành** qua `put-secret-value` — KHÔNG nằm trong TF state |
| Credential hạ tầng TF sinh (Postgres conn strings, Mongo URI, AMQP URL) | Secrets Manager `/sync/<env>/db/*`, `/sync/<env>/mq/*` | Terraform (giá trị có trong state — state bucket encrypt + private) |
| Config thường (URLs nội bộ, cờ) | env vars trong task definition | Terraform (`modules/stack/services.tf`) |

ECS inject secret qua `secrets[].valueFrom` — không plaintext trong task def/image.

## Ghi chú vận hành

- **CI deploy ngoài Terraform:** `ecs-deploy.sh` đăng ký task-def revision mới → TF
  `ignore_changes = [task_definition, desired_count]`; đừng "sửa image" bằng TF.
- **Blue/green Gateway (prod):** CodeDeploy app `sync-prod-gateway` / dg `sync-prod-gateway-dg`
  khớp `.github/scripts/ecs-bluegreen.sh`; listener bị CodeDeploy hoán đổi TG — TF ignore.
- **DB migration:** hiện các service .NET tự `Database.MigrateAsync()` lúc khởi động
  (bước migration trong workflow là no-op có chủ đích). Nâng cấp lên EF bundle one-off
  task khi cần chạy nhiều instance service có DB.
- **Mongo self-host:** backup = DLM snapshot EBS hằng ngày (giữ 7). Restore = tạo volume
  từ snapshot → attach. Quản trị qua SSM Session Manager (không mở SSH).
- **HTTPS:** có domain → tạo ACM cert (region ap-southeast-1) → điền `certificate_arn`
  trong `envs/prod/terraform.tfvars` → apply (listener 443 tự tạo).
