"""
pgvector semantic search over exercise_catalog.

Expected table (see infra/sql/exercise_catalog_pgvector.sql):
  exercise_code, name_vi, ai_coaching_cues, common_mistakes, embedding vector(1024), is_active
"""

from __future__ import annotations

import json
from typing import Any

import structlog

from sync_agent.core.config import Settings
from sync_agent.core.exceptions import VectorSearchError
from sync_agent.domain.schemas.rag.exercise_rag import ExerciseRagHit, ExerciseRagSearchResult
from sync_agent.infrastructure.rag.bge_embedder import BgeM3Embedder

logger = structlog.get_logger(__name__)

_SEARCH_SQL = """
SELECT
    exercise_code,
    name_vi,
    ai_coaching_cues,
    common_mistakes,
    (embedding <=> $1::vector) AS distance
FROM {table}
WHERE is_active = TRUE
ORDER BY embedding <=> $1::vector
LIMIT $2
"""


def _parse_string_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(v) for v in value]
    if isinstance(value, str):
        try:
            parsed = json.loads(value)
            if isinstance(parsed, list):
                return [str(v) for v in parsed]
        except json.JSONDecodeError:
            return [value]
    return []


class ExerciseCatalogSearchService:
    """Workout RAG: embed query → pgvector <=> search → slim context fields."""

    def __init__(
        self,
        *,
        settings: Settings,
        embedder: BgeM3Embedder | None = None,
    ) -> None:
        self._settings = settings
        self._embedder = embedder or BgeM3Embedder(
            model_name=settings.pgvector_embedding_model,
            dimensions=settings.pgvector_embedding_dimensions,
        )
        self._table = settings.pgvector_exercise_table

    async def search(self, query: str, *, limit: int | None = None) -> ExerciseRagSearchResult:
        top_k = limit or self._settings.pgvector_search_limit
        vector = await self._embedder.embed_query(query)

        try:
            import asyncpg
            from pgvector.asyncpg import register_vector
        except ImportError as exc:
            raise VectorSearchError(
                "asyncpg and pgvector required. Install: pip install -e '.[rag]'"
            ) from exc

        sql = _SEARCH_SQL.format(table=self._table)

        try:
            conn = await asyncpg.connect(
                self._settings.pgvector_dsn,
                timeout=self._settings.pgvector_connect_timeout_sec,
            )
            try:
                await register_vector(conn)
                rows = await conn.fetch(sql, vector, top_k)
            finally:
                await conn.close()
        except Exception as exc:
            raise VectorSearchError(f"pgvector search failed: {exc}") from exc

        hits = [
            ExerciseRagHit(
                exercise_code=row["exercise_code"],
                name_vi=row["name_vi"],
                ai_coaching_cues=_parse_string_list(row["ai_coaching_cues"]),
                common_mistakes=_parse_string_list(row["common_mistakes"]),
                distance=float(row["distance"]) if row["distance"] is not None else None,
            )
            for row in rows
        ]

        logger.info("rag.search.complete", query_len=len(query), hits=len(hits))
        return ExerciseRagSearchResult(query=query, hits=hits)
