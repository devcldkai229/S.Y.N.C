"""Embeddings OpenAI (text-embedding-3-small) cho RAG, semantic cache, long-term memory.

1536 chiều — dùng cùng provider với biometric policy (OpenAI only).
"""
from __future__ import annotations

import math
from functools import lru_cache
from typing import Any

from app.config import get_settings


@lru_cache(maxsize=1)
def _client() -> Any:
    from langchain_openai import OpenAIEmbeddings

    s = get_settings()
    return OpenAIEmbeddings(model=s.openai_embedding_model, api_key=s.openai_api_key)


async def embed_text(text: str) -> list[float]:
    """Embed 1 đoạn text -> vector. Async để không block event loop."""
    client = _client()
    if hasattr(client, "aembed_query"):
        return await client.aembed_query(text)
    return client.embed_query(text)  # fallback sync


async def embed_batch(texts: list[str]) -> list[list[float]]:
    client = _client()
    if hasattr(client, "aembed_documents"):
        return await client.aembed_documents(texts)
    return client.embed_documents(texts)


def cosine(a: list[float], b: list[float]) -> float:
    if not a or not b or len(a) != len(b):
        return 0.0
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    return dot / (na * nb) if na and nb else 0.0
