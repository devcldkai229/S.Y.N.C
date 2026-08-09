# SYNC — Terraform AWS

Hạ tầng theo kiến trúc đã chốt: **ECS on EC2 Graviton (t4g) + Spot bin-packing**,
1 ALB (Gateway) + ECS **Service Connect** nội bộ, RDS PostgreSQL 17 (+pgvector, gộp
mọi DB quan hệ), ElastiCache Redis, **SQS** (AI event queue), **MongoDB self-host EC2**
(+EBS +DLM snapshot), S3 + CloudFront thay MinIO. 2 môi trường **dev + prod**.

> **Quyết định kỹ thuật quan trọng:** t4g **không hỗ trợ ENI trunking** nên task app
> dùng `network_mode=bridge` + dynamic host port + Service Connect (thay vì awsvpc —
> awsvpc chỉ nhồi được ~2 task/instance t4g, phá vỡ bài toán bin-packing chi phí).

## Cấu trúc

```
bootstrap/          # 1 lần: S3 state bucket + DynamoDB lock (state local)
modules/
  network ecr iam-cicd iam-tasks secrets ecs-cluster ecs-service
  alb codedeploy-ecs rds redis sqs mongo-ec2 s3-cdn observability
  dns/              # Route53 + ACM us-east-1 (CloudFront ONLY — không tạo ACM ALB)
  web-static/       # S3 sync-web-<env> + CloudFront (Next.js export)
  stack/            # composite per-env: wiring toàn bộ + map service + DNS aliases
envs/
  shared/           # ECR 12 repo + GitHub OIDC roles (dùng chung dev+prod) — apply TRƯỚC
  dev/              # NAT instance, single-AZ, Spot nhiều; enable_dns=false mặc định
  prod/             # NAT GW, RDS Single-AZ db.t4g.micro, SQS, blue/green Gateway
```

## Domain + web (S3/CloudFront)

| FQDN | Target |
|---|---|
| `api.<domain>` | ALB (HTTP; HTTPS chỉ khi dán `certificate_arn` ACM **ap-southeast-1** thủ công) |
| `cdn.<domain>` | CloudFront media — **chỉ prod** (`enable_media_cdn=true`) |
| `<domain>` / `www.<domain>` | CloudFront web (`sync-web-<env>`) |

Module `dns` chỉ cấp **ACM us-east-1** (SAN: apex, www, cdn). **Không** tạo ACM cho ALB.

**Tay tại registrar:** khi `create_hosted_zone=true`, trỏ NS domain → output `dns_name_servers`.

### GitHub vars sau apply

| Variable | Terraform output |
|---|---|
| `DOMAIN_NAME` / `ENABLE_DNS` / `CREATE_HOSTED_ZONE` | tfvars / infra.yml `TF_VAR_*` |
| `WEB_BUCKET_DEV/PROD` | `web_bucket` |
| `WEB_DISTRIBUTION_ID_DEV/PROD` | `web_distribution_id` |
| `SYNC_PUBLIC_URL_*` | `api_url` (`http://api…` hoặc `https://api…` nếu có cert ALB tay) |
| Media CDN URL (app/SSM) | `cdn_url` |

Deploy web: `app-cicd.yml` job `deploy-web-*` (không Docker). Skip nếu thiếu `WEB_BUCKET_*`.

## CI — `.github/workflows/infra.yml`

Workflow plan/apply theo thứ tự **shared → dev → prod**.

| GitHub | Giá trị |
|---|---|
| Secret `AWS_OIDC_ROLE_ARN_INFRA` | output `infra_role_arn` từ `envs/shared` |
| Variable `AWS_ACCOUNT_ID` **hoặc** `TF_STATE_BUCKET` | account id / `sync-tfstate-<account>` |
| Variable `AWS_REGION` | optional, mặc định `ap-southeast-1` |
| Variable `ALERT_EMAIL` | optional (SNS alarms) |
| Variable `ACM_CERTIFICATE_ARN` | optional ACM **ap-southeast-1** cho ALB HTTPS (tay) |
| Variable `DOMAIN_NAME` | apex domain khi bật DNS |
| Variable `ENABLE_DNS` | `"true"` / `"false"` |
| Variable `CREATE_HOSTED_ZONE` | `"true"` / `"false"` |
| Environment `infra-dev` / `infra-prod` | bật Required reviewers cho prod |

CI **không** đọc `terraform.tfvars` (file gitignore) — truyền `TF_VAR_state_bucket` (+ optional khác) và patch `REPLACE_ACCOUNT_ID` trong `backend.tf` lúc chạy.

PR: fmt + validate + plan (comment). Merge `main` / `workflow_dispatch`: apply theo chuỗi trên.

> **OIDC:** role infra cho phép `pull_request` + `environment:*` + `ref:main`. Sau khi đổi `modules/iam-cicd`, apply lại `envs/shared` một lần (local hoặc CI) để trust PR plan. Deploy role cũng cần apply shared để có quyền `sync-web-*` + CloudFront invalidation.



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
# 4b. Điền config thường (SSM) — danh sách ở output ssm_param_names:
aws ssm put-parameter --overwrite --type String \
  --name /sync/dev/auth/google-client-ids --value '<value>'
# ... lặp cho từng SSM param

# 5. Init database trên RDS (tạo DB + pgvector — 1 lần):
#    chạy scripts/init-databases.sql qua bastion/SSM port-forward tới RDS
#    (mẫu port-forward trong checklist).

# 6. Push image lần đầu (tag bootstrap) để service có image chạy:
#    xem lệnh trong checklist §"Image bootstrap" — hoặc merge main để CI push tag SHA
#    rồi pipeline tự deploy.
#
#    Ví dụ push bootstrap (sau shared ECR apply):
#    for r in gateway iam ... rcm; do
#      docker build ... -t $ECR/sync/$r:bootstrap && docker push $ECR/sync/$r:bootstrap
#    done

# 7. Prod: lặp bước 3-6 với envs/prod (có manual approval qua infra.yml).
#
# Nếu đã apply bản S3 CŨ (resource aws_s3_bucket sync-*-${env}): trước apply mới,
# gỡ state để TF không destroy bucket data-source:
#   terraform state rm 'module.stack.module.s3_cdn.aws_s3_bucket.public_assets'
#   terraform state rm 'module.stack.module.s3_cdn.aws_s3_bucket.private_assets'
#   (và các resource encryption/public_access_block gắn kèm nếu còn trong state)
# Bucket có sẵn sync-pub-assets / sync-private-assets phải tồn tại trước apply.
```

## Secrets — quy ước

| Loại | Nơi chứa | Ai điền |
|---|---|---|
| Credential app THẬT (JWT, InternalApiKey, PayOS, Ahamove key, Brevo password, OpenAI, Tavily, Langfuse secret) | Secrets Manager `/sync/<env>/...` (vỏ tạo sẵn, `CHANGE_ME`) | **Người vận hành** qua `put-secret-value` — output `secret_names` |
| DB password TF sinh (Postgres, Mongo) | Secrets Manager `/sync/<env>/db/postgres-password`, `/db/mongo-password` | Terraform (giá trị trong state — state bucket encrypt + private) |
| DB config không nhạy cảm (host/port/user) | SSM Parameter Store `/sync/<env>/db/*` | Terraform — app tự ghép connection string (composer .NET / config Python) |
| Config thường người vận hành điền (Google client-ids, Langfuse public key, Ahamove mobile, Brevo username, AWS Map key) | SSM Parameter Store `/sync/<env>/...` (`CHANGE_ME`) | **Người vận hành** qua `ssm put-parameter --overwrite` — output `ssm_param_names` |
| Config thường (URLs nội bộ, cờ, SQS queue URL) | env vars trong task definition | Terraform (`modules/stack/services.tf`) |

ECS inject qua `secrets[].valueFrom` (Secrets Manager ARN **và** SSM param ARN) —
không plaintext trong task def/image. Cắt chi phí: chỉ ~5 credential lõi + third-party
nằm ở Secrets Manager; connection string ghép từ password (secret) + host/user (SSM).

## Ghi chú vận hành

- **S3 media:** TF **không tạo** bucket — `data` source trỏ `sync-pub-assets` /
  `sync-private-assets` có sẵn. Dev/prod **dùng chung bucket**; object key prefix
  `Storage__KeyPrefix=<env>/` (`dev/`, `prod/`) inject qua ECS env.
  **`enable_media_cdn`:** chỉ **prod** tạo CloudFront + OAC + `aws_s3_bucket_policy`
  trên `sync-pub-assets`. Dev (`enable_media_cdn=false`) **không** tạo CF/policy — tránh
  hai state dev/prod ghi đè bucket policy (env apply sau làm CDN env kia 403).
  Dev phục vụ media qua Gateway (`Storage__PublicBaseUrl=<api>/api/v1/media`); prod qua
  `cdn.<domain>` (output `cdn_url`). `terraform destroy` **không** xoá bucket.
- **State cleanup (nếu dev đã apply CF cũ trên bucket chung):**
  ```bash
  cd infra/aws/envs/dev
  terraform state rm 'module.stack.module.s3_cdn.aws_s3_bucket_policy.public_assets[0]'
  terraform state rm 'module.stack.module.s3_cdn.aws_cloudfront_distribution.public_assets[0]'
  terraform state rm 'module.stack.module.s3_cdn.aws_cloudfront_origin_access_control.this[0]'
  terraform state rm 'module.stack.module.s3_cdn.aws_s3_bucket_cors_configuration.public_assets[0]'
  ```
  Rồi `terraform apply` dev → prod.
- **SNS alerts:** module observability giữ SNS → email admin (CloudWatch ALB/RDS).
  Không liên quan Brevo (SMTP giao dịch user). Không dùng SES.
- **SQS (thay Amazon MQ):** queue `sync-<env>-ai-interventions` + DLQ (redrive 5 lần).
  AI worker long-poll bằng boto3 khi có `AI_SQS_QUEUE_URL`; local vẫn dùng RabbitMQ.
- **CI deploy ngoài Terraform:** `ecs-deploy.sh` đăng ký task-def revision mới → TF
  `ignore_changes = [task_definition, desired_count]`; đừng "sửa image" bằng TF.
  Sau `services-stable`, script kiểm `rolloutState` + image đang chạy == SHA vừa push.
- **Blue/green Gateway (prod):** CodeDeploy app `sync-prod-gateway` / dg `sync-prod-gateway-dg`
  khớp `.github/scripts/ecs-bluegreen.sh` — **export `CLUSTER` / `ECS_CLUSTER_PROD`**
  trước khi gọi; listener bị CodeDeploy hoán đổi TG — TF ignore.
- **DB migration:** service .NET tự `Database.MigrateAsync()` lúc khởi động.
  Workflow **không** chạy ECS task `*-migrate` (không có TD; bridge ≠ awsvpc).
- **Image bootstrap:** trước `terraform apply` lần đầu tạo ECS service, push tag
  `bootstrap` vào mọi ECR repo (`sync/<svc>:bootstrap`) hoặc để `desired_count=0`
  đến khi CI push SHA. ECR `IMMUTABLE` — rollback bằng **SHA cũ / task-def revision**
  trước đó (không dùng moving tag `:<env>-current`).
- **Mongo self-host:** backup = DLM snapshot EBS hằng ngày (giữ 7). Restore = tạo volume
  từ snapshot → attach. Quản trị qua SSM Session Manager (không mở SSH).
- **HTTPS web/cdn:** ACM **us-east-1** do module `dns` (khi `enable_dns=true`).
- **HTTPS API (ALB):** optional — tạo ACM **ap-southeast-1** tay → điền `certificate_arn` /
  `TF_VAR_certificate_arn` / `ACM_CERTIFICATE_ARN` → listener 443 + redirect 80→443.
  Module dns **không** tạo cert ALB.

## Sau deploy: migration, seed, import

### Schema (Postgres / Mongo)

| Cơ chế | Cách chạy |
|---|---|
| Postgres EF migrations | Tự động lúc service start (`ApplyMigrations` IAM, `MigrateAsync` Payment/Notification) |
| Mongo | Theo từng service (startup / manual) |
| AI DB (`sync_ai`, `sync_ai_agent`) | SQL migrations qua SSM port-forward tới RDS hoặc script init lần đầu |

Không cần ECS task `*-migrate` riêng (bridge mode; xem docs deploy).

### Seed / ImportTool

| Loại | Prod | Dev AWS | Local Docker |
|---|---|---|---|
| Demo users (IAM) | **Tắt** `SeedDemoUsers` | Bật nếu QA | Bật (compose / run-all) |
| Exercise catalog | **ImportTool 1 lần** sau deploy | Khi refresh catalog | `Exercise.ImportTool` local |
| Payment plans | Idempotent startup | OK | OK |

**ImportTool trên AWS:** SSM port-forward RDS + Mongo → chạy tool trên laptop với
`AWS_PROFILE`, connection string qua tunnel, `Storage__KeyPrefix=prod/` (hoặc `dev/`).

### Restore Postgres từ Docker/local

**Dev AWS — OK** (nhanh có data giống máy local):

```bash
pg_dump -h localhost -p 5434 -U postgres -Fc sync_iam > sync_iam.dump
# tunnel RDS dev → localhost:15432
pg_restore -h localhost -p 15432 -U postgres -d sync_iam --clean --if-exists sync_iam.dump
```

Lặp: `sync_payment`, `sync_order`, `sync_smart_push`, `sync_ai`, `sync_ai_agent`.

**Prod — không dump thẳng local → prod** (junk data, schema drift, PII). Prod: migrations +
ImportTool + seed vận hành; nếu cần rehearsal → restore vào **dev AWS** trước.

**Mongo:** `mongodump` local `:27018` → `mongorestore` qua tunnel tới EC2 Mongo (dev OK;
prod chỉ data đã duyệt).
