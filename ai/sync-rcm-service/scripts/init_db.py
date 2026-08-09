"""Initialise the sync-rcm-service database: pgvector extension, tables, and indexes.

Also migrates legacy MiniLM (vector 384) columns to OpenAI text-embedding-3-small
(vector 1536). Existing rows are truncated — run admin reindex afterwards.

Run once before first use (and safe to re-run):
    python -m scripts.init_db
"""
from __future__ import annotations

import asyncio
import os
import sys
from urllib.parse import urlparse

from sqlalchemy import text
from sqlalchemy.exc import OperationalError

from app.config import settings

_TARGET_DIM = settings.embedding_dim
_MAX_ATTEMPTS = int(os.environ.get("RCM_INIT_RETRIES", "30"))
_DELAY_SEC = float(os.environ.get("RCM_INIT_RETRY_DELAY", "2"))


def _host_from_url(url: str) -> str:
    try:
        # sqlalchemy URL may include +asyncpg
        cleaned = url.replace("postgresql+asyncpg://", "postgresql://", 1)
        return urlparse(cleaned).hostname or "?"
    except Exception:
        return "?"


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
        return

    current_dim = int(att) if att is not None and int(att) > 0 else None
    if current_dim == _TARGET_DIM:
        return

    await conn.execute(text("DROP INDEX IF EXISTS ix_embed_vector"))
    await conn.execute(text("TRUNCATE TABLE exercise_embeddings"))
    await conn.execute(
        text(f"ALTER TABLE exercise_embeddings ALTER COLUMN embedding TYPE vector({_TARGET_DIM})")
    )


async def _run_once() -> None:
    # Fresh engine per attempt (avoid disposed global engine + DNS race).
    from sqlalchemy.ext.asyncio import create_async_engine

    from app.models.database import Base

    engine = create_async_engine(settings.database_url, pool_pre_ping=True, future=True)
    try:
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
                text(
                    "CREATE INDEX IF NOT EXISTS ix_embed_difficulty ON exercise_embeddings (difficulty)"
                )
            )
            await conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_embed_body_region ON exercise_embeddings (body_region)"
                )
            )
            await conn.execute(
                text(
                    "CREATE INDEX IF NOT EXISTS ix_usage_user_month ON ai_usage_logs (user_id, created_at)"
                )
            )
    finally:
        await engine.dispose()


async def main() -> None:
    host = _host_from_url(settings.database_url)
    last_err: BaseException | None = None
    for attempt in range(1, _MAX_ATTEMPTS + 1):
        try:
            await _run_once()
            print(
                f"sync-rcm-service database initialised (embedding dim={_TARGET_DIM}, host={host}). "
                "If you migrated from 384d, run POST /api/v1/ai/admin/reindex."
            )
            return
        except (OperationalError, OSError, TimeoutError) as exc:
            last_err = exc
            print(
                f"[init_db] attempt {attempt}/{_MAX_ATTEMPTS} failed "
                f"(host={host}): {type(exc).__name__}: {exc}",
                file=sys.stderr,
                flush=True,
            )
            if attempt < _MAX_ATTEMPTS:
                await asyncio.sleep(_DELAY_SEC)
        except Exception as exc:
            # Asyncpg wrap / greenlet often surfaces as generic Exception with gaierror cause
            cause = getattr(exc, "__cause__", None) or getattr(exc, "orig", None)
            last_err = exc
            print(
                f"[init_db] attempt {attempt}/{_MAX_ATTEMPTS} failed "
                f"(host={host}): {type(exc).__name__}: {exc}"
                + (f" | cause={cause}" if cause else ""),
                file=sys.stderr,
                flush=True,
            )
            if attempt < _MAX_ATTEMPTS:
                await asyncio.sleep(_DELAY_SEC)
            else:
                break

    print(f"[init_db] giving up after {_MAX_ATTEMPTS} attempts: {last_err}", file=sys.stderr)
    raise SystemExit(1) from last_err


if __name__ == "__main__":
    asyncio.run(main())
