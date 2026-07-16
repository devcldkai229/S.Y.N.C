"""Initialise the AIAgent database: pgvector extension, tables, and indexes.

Run once before first use (and safe to re-run):
    python -m scripts.init_db
"""
import asyncio

from sqlalchemy import text

from app.models.database import Base, engine


async def main() -> None:
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        await conn.run_sync(Base.metadata.create_all)
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
    print("AIAgent database initialised.")


if __name__ == "__main__":
    asyncio.run(main())
