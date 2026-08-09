-- SYNC AI — migrate embeddings Ollama bge-m3 (1024d) -> OpenAI text-embedding-3-small (1536d).
-- CẢNH BÁO: TRUNCATE xóa toàn bộ long-term memory + knowledge base — chạy seed_knowledge sau.
--   psql "$POSTGRES_DSN" -f migrations/0002_embeddings_openai.sql
--   py scripts/seed_knowledge.py
-- Flush Redis semantic cache: DEL ai:semcache:* hoặc chờ TTL.

DROP INDEX IF EXISTS idx_ai_user_memory_emb;
DROP INDEX IF EXISTS idx_ai_knowledge_emb;

TRUNCATE ai_user_memory, ai_knowledge;

ALTER TABLE ai_user_memory ALTER COLUMN embedding TYPE vector(1536);
ALTER TABLE ai_knowledge ALTER COLUMN embedding TYPE vector(1536);

CREATE INDEX idx_ai_user_memory_emb
    ON ai_user_memory USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_ai_knowledge_emb
    ON ai_knowledge USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
