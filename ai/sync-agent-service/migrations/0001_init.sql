-- SYNC AI — schema khởi tạo cho long-term memory + knowledge RAG.
-- DB riêng `sync_ai` (Postgres + pgvector). Chạy 1 lần khi setup.
--   psql "$POSTGRES_DSN" -f migrations/0001_init.sql

CREATE EXTENSION IF NOT EXISTS vector;

-- OpenAI text-embedding-3-small -> 1536 chiều (fresh install: chạy 0002 nếu nâng từ 1024)
-- Long-term semantic memory theo user (facts/preferences/summaries)
CREATE TABLE IF NOT EXISTS ai_user_memory (
    id          BIGSERIAL PRIMARY KEY,
    user_id     UUID        NOT NULL,
    fact        TEXT        NOT NULL,
    embedding   vector(1024) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ai_user_memory_user ON ai_user_memory(user_id);
-- ANN index (cosine). ivfflat cần ANALYZE sau khi có dữ liệu.
CREATE INDEX IF NOT EXISTS idx_ai_user_memory_emb
    ON ai_user_memory USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Knowledge base RAG (fitness/nutrition đã kiểm duyệt)
CREATE TABLE IF NOT EXISTS ai_knowledge (
    id          BIGSERIAL PRIMARY KEY,
    source      TEXT        NOT NULL,
    content     TEXT        NOT NULL,
    embedding   vector(1024) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ai_knowledge_emb
    ON ai_knowledge USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Audit mỗi turn (metadata suy luận, KHÔNG PII thô) — phục vụ BI & truy vết
CREATE TABLE IF NOT EXISTS ai_turn_audit (
    id                      BIGSERIAL PRIMARY KEY,
    trace_id                UUID        NOT NULL,
    user_id                 UUID        NOT NULL,
    session_id              TEXT        NOT NULL,
    intent                  TEXT,
    tier                    TEXT,
    locale                  TEXT,
    tokens_used             INT         DEFAULT 0,
    estimated_cost_usd      NUMERIC(10,6) DEFAULT 0,
    guardrail_flags         JSONB,
    requires_confirmation   BOOLEAN     DEFAULT false,
    cache_hit               BOOLEAN     DEFAULT false,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ai_turn_audit_user ON ai_turn_audit(user_id, created_at DESC);
