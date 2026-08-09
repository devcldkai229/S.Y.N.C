# SYNC Platform — Docker Compose (local full stack)

Chạy **toàn bộ** stack container (infra + 13 backend + UI) trước khi deploy AWS/ECS.

## Quick start

```powershell
cd infra/docker
copy .env.example .env
# Bắt buộc điền nếu cần AI/chat: OPENAI_API_KEY=sk-...
# S3 media: mount ~/.aws hoặc AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY

.\scripts\up-full.ps1 -Build
```

Linux/macOS:

```bash
cd infra/docker
cp .env.example .env
# edit .env
chmod +x scripts/up-full.sh
./scripts/up-full.sh --build
```

## Secrets trong `.env`

| Nhóm | Biến | Ghi chú |
|------|------|---------|
| JWT | `JWT_SIGNING_KEY`, issuer, audience | **Giống nhau** mọi service; không dùng ký tự `$` thuần |
| Internal | `INTERNAL_API_KEY` | Gọi service-to-service |
| AWS S3 | keys hoặc profile `~/.aws` | Bucket thật `sync-*-assets` |
| LLM | `OPENAI_API_KEY`, `TAVILY_API_KEY` | AI / RCM / SmartPush |
| PayOS | `PAYOS_*` | Mẫu dev trong `.env.example` |
| Google | `GOOGLE_CLIENT_ID` | Sign-In |
| Brevo | `BREVO_*` | Mặc định `BREVO_ENABLED=false` |
| Ahamove | `AHAMOVE_*` | Sandbox mặc định |
| Legal web | `NEXT_PUBLIC_LEGAL_*` | Policy pages |

## Profiles

| Profile | Nội dung |
|---------|----------|
| *(default)* | Postgres+pgvector, Mongo, Redis, RabbitMQ |
| `app` | IAM…Order, Gateway, AI, ai-worker, RCM, rcm-init |
| `ui` | Admin Next (:3000), Flutter web (:3002) |
| `optional` | Ollama, Langfuse |

```bash
docker compose --profile app --profile ui up -d --build
```

## URLs (host)

| Service | URL |
|---------|-----|
| Gateway | http://localhost:5057/health |
| IAM | http://localhost:5288/health |
| AI | http://localhost:8088/healthz |
| RCM | http://localhost:5300/health |
| Admin web | http://localhost:3000 |
| Flutter web | http://localhost:3002 |
| RabbitMQ | http://localhost:15672 (`sync_mq_user` / `.env`) |

Demo users: `Iam` seed — password `SyncDemo123!` (đổi bằng `IAM_DEMO_USER_PASSWORD`).

## Sau khi up

```powershell
docker compose --profile app ps
docker compose --profile app logs -f gateway iam ai
curl http://localhost:5057/health
```

Fresh DB: `docker compose --profile app --profile ui down -v` rồi up lại (xóa volumes).

## Khác AWS

| Local | ECS prod |
|-------|----------|
| RabbitMQ | SQS |
| Compose DNS `http://iam:8080` | Service Connect |
| `.env` secrets | Secrets Manager / SSM |
| `Dockerfile.compose` | production chiseled `Dockerfile` |
