-- pgvector catalog for Workout RAG (Python agent connects here only — not C# core DBs).
-- Run against a dedicated database, e.g. sync_vector on the Postgres instance.

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS exercise_catalog (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_code   TEXT NOT NULL UNIQUE,
    name_vi         TEXT,
    ai_coaching_cues JSONB NOT NULL DEFAULT '[]'::jsonb,
    common_mistakes  JSONB NOT NULL DEFAULT '[]'::jsonb,
    embedding       vector(1024) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_exercise_catalog_embedding
    ON exercise_catalog
    USING hnsw (embedding vector_cosine_ops);
