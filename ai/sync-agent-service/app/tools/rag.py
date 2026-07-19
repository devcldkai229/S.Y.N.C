"""RAG kiến thức fitness/nutrition đã kiểm duyệt (chống bịa).

MVP: corpus tĩnh nạp từ `app/knowledge/*.md`, embed OpenAI (1536d), lưu pgvector
(bảng `ai_knowledge`). Truy hồi top-k theo cosine. Nguồn sự thật DỮ LIỆU NGƯỜI DÙNG
vẫn là .NET; RAG chỉ cho kiến thức chung.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from app.config import get_settings
from app.models.embeddings import embed_text


@dataclass
class KnowledgeChunk:
    source: str
    text: str
    score: float


class FitnessKnowledgeBase:
    def __init__(self, pool: Any = None, dsn: str | None = None) -> None:
        self._pool = pool
        self.dsn = dsn or get_settings().postgres_dsn

    async def _pool_or_create(self) -> Any:
        if self._pool is not None:
            return self._pool
        from app.deps import get_pg_pool

        pool = get_pg_pool()
        if pool is not None:
            return pool
        import asyncpg

        return await asyncpg.create_pool(self.dsn, min_size=1, max_size=4)

    async def search(self, query: str, k: int = 4) -> list[KnowledgeChunk]:
        emb = await embed_text(query)
        vec = "[" + ",".join(str(x) for x in emb) + "]"
        pool = await self._pool_or_create()
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT source, content, 1 - (embedding <=> $1) AS score
                FROM ai_knowledge
                ORDER BY embedding <=> $1
                LIMIT $2
                """,
                vec, k,
            )
        return [KnowledgeChunk(r["source"], r["content"], float(r["score"])) for r in rows]


async def rag_fitness_kb(query: str, k: int = 4) -> str:
    """Trả về context block (có trích nguồn) để chèn vào prompt."""
    try:
        from app.deps import get_fitness_kb

        kb = get_fitness_kb()
        if kb is None:
            kb = FitnessKnowledgeBase()
        chunks = await kb.search(query, k)
    except Exception:  # pragma: no cover — KB chưa nạp
        return ""
    if not chunks:
        return ""
    return "\n\n".join(f"[Nguồn: {c.source}] {c.text}" for c in chunks if c.score > 0.3)
