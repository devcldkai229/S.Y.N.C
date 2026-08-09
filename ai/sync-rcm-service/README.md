# sync-rcm-service

FastAPI microservice that powers **1-click AI workout generation** and
**single-exercise swap** in the mobile app's "Tạo lộ trình mới" flow
(recommendation / RCM).

Pipeline (tiered intelligence):
1. **Context** — forward the user JWT to IAM (`/biometrics`, `/me/profile-settings`)
   and Roadmap (`/recovery-profiles`, `/workout-executions`).
2. **SQL filter** — drop exercises above the user's level or hitting injured regions.
3. **Embedding rank** — OpenAI `text-embedding-3-small` (1536d) + pgvector cosine
   distance, excluding already-used codes (same embed model as sync-agent-service).
4. **OpenAI LLM** (`gpt-4o-mini`) — assemble the session / pick a replacement
   (falls back to the top-ranked candidates if no API key is configured).

## Endpoints (all behind the gateway at `/api/v1/ai/...`)
- `POST /api/v1/ai/workout/generate-session-exercises` — AI generate exercises for a session.
- `POST /api/v1/ai/workout/swap-exercise` — suggest one alternative exercise.
- `POST /api/v1/ai/admin/reindex` *(SystemAdmin)* — (re)embed the exercise catalog.
- `GET  /api/v1/ai/admin/stats` *(SystemAdmin)* — embedded count.
- `GET  /health`

## Run locally
```bash
cp .env.example .env          # set OPENAI_API_KEY
pip install -r requirements.txt
python -m scripts.init_db     # create/migrate pgvector (384→1536 truncates old rows)
# Preferred (from SyncPlatform):
#   .\scripts\run-all.ps1 --rcm
# Or manual:
python -m uvicorn app.main:app --host 0.0.0.0 --port 5300
# then login as SystemAdmin and POST /api/v1/ai/admin/reindex once
```

Gateway (local) must route workout/admin to this service **before** the chatbot catch-all:

- `/api/v1/ai/workout/**` → `http://localhost:5300` (`rcm-cluster`)
- `/api/v1/ai/admin/**` → `http://localhost:5300`
- `/api/v1/ai/**` (chat) → sync-agent `:8088`

See `core/SyncPlatform/src/Gateway/appsettings.json.example`. Restart Gateway after changing routes.

## Migration to OpenAI embeddings
1. Update `.env` to `OPENAI_*` (see `.env.example`).
2. Run `python -m scripts.init_db` — upgrades `embedding` to `vector(1536)` and
   truncates incompatible rows.
3. `POST /api/v1/ai/admin/reindex` with a SystemAdmin token.

## Docker / local DB
Local test (host process, not packaged): use shared `sync-postgres` on host
port **5434** — `DATABASE_URL=postgresql+asyncpg://postgres:12345@localhost:5434/sync_ai_agent`
(see `.env`). Optional dedicated `sync-ai-postgres` (:5435) in compose is
commented out; only needed if you run the `rcm` container profile.
