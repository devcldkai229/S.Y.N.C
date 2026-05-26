"""BAAI/bge-m3 dense embeddings for Workout RAG."""

from __future__ import annotations

import asyncio
from functools import lru_cache

import structlog

from sync_agent.core.exceptions import EmbeddingError

logger = structlog.get_logger(__name__)


@lru_cache(maxsize=1)
def _load_model(model_name: str):
    try:
        from sentence_transformers import SentenceTransformer
    except ImportError as exc:
        raise EmbeddingError(
            "sentence-transformers required for RAG. Install: pip install -e '.[rag]'"
        ) from exc

    logger.info("embedding.model.loading", model=model_name)
    return SentenceTransformer(model_name)


class BgeM3Embedder:
    """Generates normalized dense vectors (1024-dim for bge-m3)."""

    def __init__(self, *, model_name: str = "BAAI/bge-m3", dimensions: int = 1024) -> None:
        self._model_name = model_name
        self._dimensions = dimensions
        self._model = None

    def _get_model(self):
        if self._model is None:
            self._model = _load_model(self._model_name)
        return self._model

    async def embed_query(self, text: str) -> list[float]:
        cleaned = text.strip()
        if not cleaned:
            raise EmbeddingError("Cannot embed empty query")

        def _encode() -> list[float]:
            model = self._get_model()
            vector = model.encode(cleaned, normalize_embeddings=True)
            return vector.tolist()

        try:
            vector = await asyncio.to_thread(_encode)
        except Exception as exc:
            raise EmbeddingError(f"Embedding failed: {exc}") from exc

        if len(vector) != self._dimensions:
            logger.warning(
                "embedding.dimension.mismatch",
                expected=self._dimensions,
                actual=len(vector),
            )
        return vector
