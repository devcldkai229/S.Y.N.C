# SYNC AIAgent Service

FastAPI microservice that powers **1-click AI workout generation** and
**single-exercise swap** in the mobile app's "Tạo lộ trình mới" flow.

Pipeline (tiered intelligence):
1. **Context** — forward the user JWT to IAM (`/biometrics`, `/me/profile-settings`)
   and Roadmap (`/recovery-profiles`, `/workout-executions`).
2. **SQL filter** — drop exercises above the user's level or hitting injured regions.
3. **Embedding rank** — local `paraphrase-multilingual-MiniLM-L12-v2` + pgvector
   cosine distance, excluding already-used codes.
4. **DeepSeek LLM** — assemble the session / pick a replacement (falls back to the
   top-ranked candidates if no API key is configured).

## Endpoints (all behind the gateway at `/api/v1/ai/...`)
- `POST /api/v1/ai/workout/generate-session-exercises` — AI generate exercises for a session.
- `POST /api/v1/ai/workout/swap-exercise` — suggest one alternative exercise.
- `POST /api/v1/ai/admin/reindex` *(SystemAdmin)* — (re)embed the exercise catalog.
- `GET  /api/v1/ai/admin/stats` *(SystemAdmin)* — embedded count.
- `GET  /health`

## Run locally
```bash
cp .env.example .env          # set DEEPSEEK_API_KEY
pip install -r requirements.txt
python -m scripts.init_db     # create pgvector extension + tables (needs the AI postgres)
uvicorn app.main:app --port 8000
# then login as SystemAdmin and POST /api/v1/ai/admin/reindex once
```

## Docker
`docker compose up -d sync-ai-postgres aiagent` (from `infra/docker`). The AI
service is exposed on host port **5300**; pgvector on **5435**.
The gateway route `ai-route` forwards `/api/v1/ai/{**catch-all}` → `http://localhost:5300`.
