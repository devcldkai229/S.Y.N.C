"""Initialise the sync-rcm-service database: pgvector extension, tables, and indexes.

Also migrates legacy MiniLM (vector 384) columns to OpenAI text-embedding-3-small
(vector 1536). Existing rows are truncated — run admin reindex afterwards.

Run once before first use (and safe to re-run):
    python -m scripts.init_db
"""
import asyncio

from sqlalchemy import text

from app.config import settings
from app.models.database import Base, engine

_TARGET_DIM = settings.embedding_dim


async def _ensure_embedding_dim(conn) -> None:
    """Upgrade exercise_embeddings.embedding to vector(1536) if needed."""
    row = await conn.execute(
        text(
            """
            SELECT atttypmod
            FROM pg_attribute a
            JOIN pg_class c ON a.attrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE c.relname = 'exercise_embeddings'
              AND a.attname = 'embedding'
              AND n.nspname = current_schema()
              AND NOT a.attisdropped
            """
        )
    )
    att = row.scalar_one_or_none()
    if att is None:
        return  # table not created yet; create_all will use current Vector(dim)

    # pgvector stores dimension in atttypmod (actual dim, or -1 if unconstrained)
    current_dim = int(att) if att is not None and int(att) > 0 else None
    if current_dim == _TARGET_DIM:
        return

    await conn.execute(text("DROP INDEX IF EXISTS ix_embed_vector"))
    await conn.execute(text("TRUNCATE TABLE exercise_embeddings"))
    await conn.execute(
        text(f"ALTER TABLE exercise_embeddings ALTER COLUMN embedding TYPE vector({_TARGET_DIM})")
    )


async def main() -> None:
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        await conn.run_sync(Base.metadata.create_all)
        await _ensure_embedding_dim(conn)
        await conn.execute(
            text(
                "CREATE INDEX IF NOT EXISTS ix_embed_vector ON exercise_embeddings "
                "USING ivfflat (embedding vector_cosine_ops) WITH (lists = 20)"
            )
        )
        await conn.execute(
            text("CREATE INDEX IF NOT EXISTS ix_embed_difficulty ON exercise_embeddings (difficulty)")
        )
        await conn.execute(
            text("CREATE INDEX IF NOT EXISTS ix_embed_body_region ON exercise_embeddings (body_region)")
        )
        await conn.execute(
            text("CREATE INDEX IF NOT EXISTS ix_usage_user_month ON ai_usage_logs (user_id, created_at)")
        )
    await engine.dispose()
    print(
        f"sync-rcm-service database initialised (embedding dim={_TARGET_DIM}). "
        "If you migrated from 384d, run POST /api/v1/ai/admin/reindex."
    )


if __name__ == "__main__":
    asyncio.run(main())
