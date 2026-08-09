# SYNC AI Agent Service

Multi-agent AI layer (Python · LangGraph · FastAPI) cho nền tảng SYNC.
Đây là **scaffolding** minh hoạ kiến trúc trong `docs/ai-agents/SYNC-MultiAgent-Architecture.md`.

## Cấu trúc

```
ai/sync-agent-service/
├── pyproject.toml
├── .env.example
├── app/
│   ├── config.py            # Settings + model registry (OpenAI)
│   ├── state.py             # SyncAgentState (LangGraph state)
│   ├── models/
│   │   └── router.py        # Model routing đa tầng (nano→realtime)
│   ├── graph/
│   │   ├── build.py         # Lắp ráp StateGraph (supervisor + specialists)
│   │   ├── supervisor.py    # Orchestrator: intent + ngôn ngữ + tier
│   │   ├── guardrails.py    # Guardrail IN/OUT, spending gate
│   │   └── agents/
│   │       ├── coach.py
│   │       ├── workout.py
│   │       ├── nutrition.py
│   │       ├── commerce.py
│   │       └── insight.py
│   ├── tools/
│   │   └── dotnet.py        # Async adapters gọi .NET services (Internal API Key)
│   ├── memory/
│   │   └── checkpointer.py  # Redis short-term + pgvector long-term
│   ├── voice/
│   │   └── realtime.py      # Realtime voice gateway (OpenAI Realtime bridge)
│   └── api/
│       └── main.py          # FastAPI: /ai/chat (SSE), /ai/voice, /ai/realtime (WS)
└── tests/
    └── test_smoke.py
```

## Chạy thử (local) — MVP Chat

```bash
cd ai/sync-agent-service
cp .env.example .env                 # OPENAI_API_KEY, INTERNAL_API_KEY, JWT_SIGNING_KEY...
py -m pip install -e ".[dev]"        # hoặc: uv sync

# 1) Hạ tầng — Docker (khuyến nghị) hoặc local:
cd infra/docker
docker compose up -d sync-postgres sync-redis sync-rabbitmq
# Postgres: pgvector; DB sync_ai tạo qua init-db/ (volume mới). Langfuse: profile optional.
# hoặc thủ công: psql ... -c "CREATE DATABASE sync_ai" + CREATE EXTENSION vector

psql "postgresql://postgres:12345@localhost:5434/sync_ai" -f migrations/0001_init.sql
# Nâng cấp embeddings Ollama 1024d -> OpenAI 1536d (TRUNCATE memory + KB):
psql "postgresql://postgres:12345@localhost:5434/sync_ai" -f migrations/0002_embeddings_openai.sql

# 2) Seed knowledge base (RAG) — bắt buộc sau migration 0002:
py scripts/seed_knowledge.py

# 3) Chạy service:
py -m uvicorn app.api.main:app --reload --port 8088
```

Hạ tầng / full stack qua Docker Compose — xem `infra/docker/README.md`:

```bash
cd infra/docker
cp .env.example .env
docker compose --profile app --profile ui up -d --build   # Gateway + AI + web
# Chỉ infra:
docker compose up -d
```

Chạy **chỉ AI trên host** (hybrid): infra compose + `uvicorn` như bước 3 bên dưới.

`.env` phải khớp IAM dev: `JWT_ISSUER=sync-lifestyle-iam-dev`, `INTERNAL_API_KEY=dev_internal_api_key_sync_platform`, v.v. (xem `.env.example`).

**API keys bắt buộc:** `OPENAI_API_KEY` (mọi tier chat, intent classifier, embeddings, mọi prompt có biometric).

**Ollama (tuỳ chọn dev):** `py -m pip install -e ".[local]"` + `INTENT_CLASSIFIER_PROVIDER=ollama` — không dùng trong registry mặc định.

Sau migration 0002, flush semantic cache Redis: `redis-cli -n 2 KEYS "ai:semcache:*" | xargs redis-cli -n 2 DEL` (hoặc chờ TTL).

### Thử endpoint chat (SSE)

```bash
curl -N -X POST http://localhost:8088/ai/chat \
  -H "Authorization: Bearer <JWT_TỪ_IAM>" \
  -H "Content-Type: application/json" \
  -d '{"message":"hôm nay mình nên ăn bao nhiêu protein?","session_id":"sess-1"}'
```

### Test offline (không cần LLM/network)

```bash
pytest -q tests          # smoke + routing eval + guardrail
ruff check app tests
```

## Trạng thái MVP Chat (P0)

| Thành phần | Trạng thái |
|-----------|-----------|
| FastAPI + JWT + rate-limit theo tier | ✅ |
| LangGraph: guardrail_in → load_context → supervisor → agent → guardrail_out | ✅ |
| **Intent routing bằng LLM** (đọc-hiểu-phân loại, JSON) + cache + fallback VN không dấu | ✅ |
| Prompt library tiếng Việt (versioned) + LLM tool-calling | ✅ |
| Model router (OpenAI) + streaming | ✅ |
| Coach / Nutrition / Workout(read) agents | ✅ |
| .NET tool adapters (Internal API Key + ApiResponse unwrap) | ✅ |
| Redis checkpointer + pgvector memory + RAG KB | ✅ |
| Guardrail PII/injection/safety + audit | ✅ |
| Langfuse tracing + Prometheus metrics | ✅ |
| IAM `/api/internal/ai-context/{id}/full-context` + Gateway `ai-route` | ✅ |
| Async voice / Realtime voice | ⏳ P2 |
| Commerce-Order + auto-order + events | ⏳ P1 (`propose_order` local; `create_order` internal API sẵn sàng) |

## Tích hợp .NET (internal API)

AI gọi trực tiếp microservice qua `X-Internal-Api-Key` + `userId` trong path/body (`app/tools/dotnet.py`):

| Tool Python | Endpoint .NET |
|-------------|---------------|
| `get_user_snapshot` | `GET IAM /api/internal/ai-context/{userId}/full-context` |
| `get_today_workout` | `GET Roadmap /api/internal/workout-activity/today/{userId}` |
| `request_replan` | `POST Roadmap /api/internal/roadmap/replan` (queue ticket) |
| `adjust_intensity` | `POST Roadmap /api/internal/roadmap/sessions/{id}/adjust-intensity` |
| `get_daily_summary` | `GET Nutrition /api/internal/nutrition/daily-summary/{userId}` |
| `log_meal` | `POST Nutrition /api/internal/nutrition/meal-logs` |
| `recommend_partner_meals` | `GET Marketplace /api/internal/marketplace/recommendations` |
| `check_wallet` | `GET Payment /api/internal/wallet/{userId}/balance` |
| `create_order` | `POST Order /api/internal/orders` |
| `track_order` | `GET Order /api/internal/orders/{id}/tracking?userId=` |
| `send_notification` | `POST Notification /api/internal/notifications/send` |

Gateway: `POST /api/v1/ai/chat` → `localhost:8088` (`ai-route` trong Gateway appsettings).

### Lịch tập (plan_or_edit_workout / confirm)

1. Seed catalog Exercise (`Exercise.ImportTool import-free-exercise-db`) — Mongo `sync_exercise.ExerciseCatalog` không rỗng.
2. Chat gọi tool → SSE `pending_action` (lưu thêm Redis TTL `PENDING_ACTION_TTL_SECONDS`, mặc định 30 phút).
3. User bấm Xác nhận → `POST /ai/chat/confirm` (lookup graph + Redis; turn chat sau vẫn confirm được trong TTL).
4. Write: `POST Roadmap .../sessions/schedule-week` (timeout 30s).

## Triết lý

- **Right model for right task** — xem `app/models/router.py`.
- **Tool-first** cho số liệu/tiền (macro, giá, đặt hàng) — LLM không tự tính.
- **Guardrail là node bắt buộc** — IN (PII/injection) và OUT (safety/spending).
- **Non-blocking** — async toàn bộ; tác vụ nặng đẩy queue.

> Scaffolding tập trung vào *cấu trúc & luồng*; phần gọi LLM/tool có chỗ đánh dấu `# TODO` để nối hạ tầng thật.
