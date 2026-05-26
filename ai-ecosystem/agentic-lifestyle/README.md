# SYNC Agentic Lifestyle — Phase 1: Voice Gateway

Real-time bi-directional WebSocket gateway for the Flutter client: ingest PCM audio, transcribe via **Groq Whisper**, stream Vietnamese speech via **TravisVN Edge TTS**.

## Architecture

```
Flutter App
    │  WebSocket (JSON control + binary PCM)
    ▼
FastAPI  sync_agent/api/routes/voice.py
    ▼
VoiceWebSocketHandler → VoicePipeline
    ├── GroqSpeechToText   (whisper-large-v3)
    └── TravisTextToSpeech (openai-edge-tts, vi-VN-HoaiMyNeural)
```

**Boundary:** Python never touches C# databases in this phase. LangGraph workers arrive in Phase 2.

## Project layout

```
agentic-lifestyle/
├── pyproject.toml
├── .env.example
├── rules/                    # .cursorrules — master AI context
├── scripts/run-dev.ps1
├── src/sync_agent/
│   ├── main.py               # Uvicorn entry
│   ├── core/                 # config, logging, exceptions
│   ├── domain/voice/         # protocol, session, buffer
│   ├── application/          # pipeline, text chunking
│   ├── infrastructure/       # Groq STT, Travis TTS
│   └── api/                  # FastAPI app, WebSocket handler
└── tests/
```

## Quick start

```powershell
cd ai-ecosystem/agentic-lifestyle
copy .env.example .env
# Edit .env → set SYNC_GROQ_API_KEY

.\scripts\run-dev.ps1
# Or: pip install -e ".[dev]" && sync-agent
```

- HTTP health: `GET http://localhost:8100/health`
- Voice WS: `ws://localhost:8100/ws/voice`
- OpenAPI (debug): `http://localhost:8100/docs`

## WebSocket protocol

### 1. Bind session (JSON)

```json
{
  "type": "session.bind",
  "user_id": "uuid",
  "session_id": "uuid",
  "current_time": "2026-05-22T10:00:00+07:00",
  "audio_format": { "codec": "pcm_s16le", "sample_rate": 16000, "channels": 1 }
}
```

Server → `session.ready`

### 2. Stream audio (binary)

Send PCM **s16le**, 16 kHz, mono chunks while the user speaks.

### 3. End utterance (JSON)

```json
{ "type": "audio.flush" }
```

Server sequence:

| Order | Message | Description |
|-------|---------|-------------|
| 1 | `pipeline.start` | Processing began |
| 2 | `stt.final` | Groq transcript |
| 3 | `assistant.text` | Phase-1 placeholder reply |
| 4 | `tts.start` | Audio format metadata |
| 5 | *binary MP3 chunks* | Streamed TTS per sentence segment |
| 6 | `tts.end` | Audio stream complete |
| 7 | `pipeline.end` | Ready for next utterance |

### Other control messages

| Client | Purpose |
|--------|---------|
| `audio.clear` | Discard buffered PCM |
| `cancel` | Abort in-flight pipeline |
| `ping` | Keep-alive → `pong` |

### Errors

```json
{ "type": "error", "code": "stt_failed", "message": "..." }
```

## Flutter integration notes

- Use `web_socket_channel` or equivalent.
- Record 16 kHz mono PCM; send bind before first binary frame.
- On `audio.flush`, play incoming binary as MP3 segments (concat or queue player).
- Call `audio.flush` on VAD end-of-speech or push-to-talk release.

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SYNC_GROQ_API_KEY` | — | **Required** for STT |
| `SYNC_GROQ_STT_MODEL` | `whisper-large-v3` | Groq model |
| `SYNC_GROQ_STT_LANGUAGE` | `vi` | ISO-639-1 hint |
| `SYNC_TTS_BASE_URL` | `https://tts.travisvn.com/v1` | Travis OpenAI-compatible API |
| `SYNC_TTS_VOICE` | `vi-VN-HoaiMyNeural` | Vietnamese voice |
| `SYNC_PORT` | `8100` | HTTP/WS port |

## Tests

```powershell
pip install -e ".[dev]"
pytest
```

## Phase 4: Agentic brain & guardrails

```python
from sync_agent.core.config import get_settings
from sync_agent.application.agent_runner import AgentRunner

settings = get_settings()
runner = AgentRunner.from_settings(settings, bearer_token="<jwt>")
state = await runner.run_turn(
    user_message="Trưa nay ăn gà rán 1000 calo, tối ăn gì?",
    user_id="...",
)
print(state["spoken_response"], state["tool_calls"])
```

| Node | Model | Output |
|------|-------|--------|
| `router` | Groq `llama-3.1-8b-instant` | `current_intent` |
| `nutrition_worker` | OpenAI `gpt-4o-mini` | JSON schema `spoken_response` + `tool_calls` |
| `nutrition_guardrail` | Python deterministic | Allergy + disliked food check → retry |
| `workout_rag_worker` | OpenAI + pgvector context | JSON schema |
| `workout_action_worker` | OpenAI + roadmap/recovery JIT | JSON schema |

Install: `pip install -e ".[agent]"`  
Env: `SYNC_OPENAI_API_KEY`, `SYNC_GROQ_API_KEY`

## Phase 5: Orchestration & event-driven execution

Full graph: `router → workers → nutrition_guardrail → tool_execution → END`

Voice WebSocket (`/ws/voice`) streams TTS **concurrently** with RabbitMQ tool publishing:
after `spoken_response` is ready, TTS runs in a background task while `tool_execution` publishes commands.

```json
// session.bind — include JWT for JIT HTTP
{"type":"session.bind","user_id":"...","session_id":"...","access_token":"<jwt>"}
```

| Component | Role |
|-----------|------|
| `tool_execution_node` | Iterates `tool_calls`, SHA-256 idempotency key, publishes to RabbitMQ |
| `RabbitMQCommandPublisher` | Durable topic exchange `sync.agent.commands`, queue `workout_commands` |
| `InMemoryIdempotencyStore` | Python-side dedup per process (C# uses Redis) |

Message envelope (`AgentCommandMessage`): `idempotencyKey`, `userId`, `action`, `payload`, `publishedAt`.

Env: `SYNC_RABBITMQ_URL`, `SYNC_RABBITMQ_ENABLED`  
Start broker: `docker compose -f infra/docker/docker-compose.yml up sync-rabbitmq -d`

## Phase 3: JIT HTTP clients & Workout RAG

### JIT context (C# via Gateway)

```python
from sync_agent.core.config import get_settings
from sync_agent.infrastructure.http import JitContextFetcher, SyncApiClient

settings = get_settings()
api = SyncApiClient(settings=settings, bearer_token="<jwt>")
fetcher = JitContextFetcher(api)
context = await fetcher.fetch()  # partial failures tolerated
```

| HTTP (Gateway) | Domain model |
|----------------|--------------|
| `GET /api/v1/biometrics` | `BiometricProfile` |
| `GET /api/v1/me/profile-settings` | `UserPreference` |
| `GET /api/v1/roadmap/roadmaps` | `PersonalizedRoadmap` (active) |
| `GET /api/v1/roadmap/recovery-profiles` | `RecoveryProfile` (latest) |

`AIContextProfile`: no public API yet — returns `None` until IAM exposes an endpoint.

Retries: configurable `SYNC_GATEWAY_MAX_RETRIES` with exponential backoff on 408/429/5xx and network errors.

### Workout RAG (pgvector)

```python
from sync_agent.infrastructure.rag import ExerciseCatalogSearchService

rag = ExerciseCatalogSearchService(settings=get_settings())
result = await rag.search("squat bị đau lưng dưới")
print(result.to_prompt_context())  # AiCoachingCues + CommonMistakes only
```

Setup DB: `infra/sql/exercise_catalog_pgvector.sql`  
Install: `pip install -e ".[rag]"`

## Phase 2: Domain schemas & LangGraph state

Strict Pydantic V2 mirrors of C# entities (`extra=forbid`, camelCase JSON from .NET APIs):

| Python model | C# source |
|--------------|-----------|
| `BiometricProfile` | `Iam.Domain.Models.BiometricProfile` |
| `UserPreference` + `AllergyItem` | `Iam.Domain.Models` |
| `AIContextProfile` | `Iam.Domain.Models.AIContextProfile` |
| `PersonalizedRoadmap` | `Roadmap.Domain.Models.PersonalizedRoadmap` |
| `RecoveryProfile` | `Roadmap.Domain.Models.RecoveryProfile` (JIT for workout action) |

```python
from sync_agent.domain import AgentState, JitContext, BiometricProfile
from sync_agent.domain.schemas import LLMAgentOutput, ToolCall
```

`AgentState` (TypedDict) tracks: `chat_history`, `latest_message`, `current_intent`, `jit_context`, `spoken_response`, `tool_calls`.

Optional LangGraph deps: `pip install -e ".[agent]"`

## Roadmap

- **Phase 6:** C# RabbitMQ consumers + Redis idempotency on `workout_commands`

See `rules/.cursorrules` for full platform context.
