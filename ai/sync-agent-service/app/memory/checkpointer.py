"""Memory: short-term checkpointer (Redis) + long-term semantic (pgvector).

- Short-term: LangGraph checkpointer ở Redis -> resume hội thoại qua nhiều turn.
- Long-term: facts/preferences user + tóm tắt, truy hồi theo embedding (pgvector).
Nguồn sự thật dữ liệu user vẫn là .NET services; long-term chỉ lưu suy luận/tóm tắt.
"""
from __future__ import annotations

from typing import Any

from app.config import get_settings
from app.models.embeddings import embed_text


async def build_checkpointer() -> Any:
    """Tạo Redis checkpointer cho LangGraph (async). Fallback MemorySaver khi dev."""
    settings = get_settings()
    try:
        from langgraph.checkpoint.redis.aio import AsyncRedisSaver

        saver = AsyncRedisSaver(redis_url=settings.redis_url)
        if hasattr(saver, "asetup"):
            await saver.asetup()
        return saver
    except Exception:  # pragma: no cover — fallback in-memory cho dev/test
        from langgraph.checkpoint.memory import MemorySaver

        return MemorySaver()


class SemanticMemory:
    """Long-term memory trên Postgres + pgvector."""

    def __init__(self, pool: Any = None, dsn: str | None = None) -> None:
        self._pool = pool
        self._owns_pool = False
        self.dsn = dsn or get_settings().postgres_dsn

    async def _pool_or_create(self) -> Any:
        if self._pool is not None:
            return self._pool
        from app.deps import get_pg_pool

        pool = get_pg_pool()
        if pool is not None:
            self._pool = pool
            return pool
        import asyncpg

        self._pool = await asyncpg.create_pool(self.dsn, min_size=1, max_size=5)
        self._owns_pool = True
        return self._pool

    async def remember(self, user_id: str, fact: str) -> None:
        emb = await embed_text(fact)
        pool = await self._pool_or_create()
        vec = "[" + ",".join(str(x) for x in emb) + "]"
        async with pool.acquire() as conn:
            await conn.execute(
                "INSERT INTO ai_user_memory(user_id, fact, embedding) VALUES($1,$2,$3)",
                user_id, fact, vec,
            )

    async def recall(self, user_id: str, query: str, k: int = 5) -> list[str]:
        emb = await embed_text(query)
        vec = "[" + ",".join(str(x) for x in emb) + "]"
        pool = await self._pool_or_create()
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT fact FROM ai_user_memory
                WHERE user_id = $1
                ORDER BY embedding <=> $2
                LIMIT $3
                """,
                user_id, vec, k,
            )
        return [r["fact"] for r in rows]

    async def close(self) -> None:
        if self._owns_pool and self._pool is not None:
            await self._pool.close()
            self._pool = None
