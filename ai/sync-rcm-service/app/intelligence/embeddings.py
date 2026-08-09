"""OpenAI embeddings (text-embedding-3-small, 1536d) — same as sync-agent-service."""
from __future__ import annotations

from openai import AsyncOpenAI

from app.config import settings

_BATCH_SIZE = 64


def _client() -> AsyncOpenAI:
    if not settings.openai_api_key:
        raise RuntimeError("OpenAI API key not configured — cannot embed.")
    return AsyncOpenAI(api_key=settings.openai_api_key, base_url=settings.openai_base_url)


async def embed_text(text: str) -> list[float]:
    client = _client()
    resp = await client.embeddings.create(
        model=settings.openai_embedding_model,
        input=text,
    )
    return list(resp.data[0].embedding)


async def embed_batch(texts: list[str]) -> list[list[float]]:
    if not texts:
        return []
    client = _client()
    out: list[list[float]] = []
    for i in range(0, len(texts), _BATCH_SIZE):
        chunk = texts[i : i + _BATCH_SIZE]
        resp = await client.embeddings.create(
            model=settings.openai_embedding_model,
            input=chunk,
        )
        # API returns data sorted by index
        ordered = sorted(resp.data, key=lambda d: d.index)
        out.extend(list(item.embedding) for item in ordered)
    return out
