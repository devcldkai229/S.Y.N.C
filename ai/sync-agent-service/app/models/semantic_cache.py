"""Semantic cache: exact hash (O(1)) + optional vector layer (tắt mặc định MVP).

Cache key LUÔN tách theo persona + motivation + locale (+ agent) để không trả nhầm giọng.
"""
from __future__ import annotations

import hashlib
import json
import time

from app.config import get_settings
from app.models.embeddings import cosine, embed_text

_INDEX_KEY = "ai:semcache:index"
_ENTRY_PREFIX = "ai:semcache:entry:"
_EXACT_PREFIX = "ai:semcache:exact:"


def style_scope(
    *,
    persona: str = "FriendlyBuddy",
    motivation: str = "Supportive",
    locale: str = "vi",
    agent: str = "*",
    base: str = "global",
) -> str:
    """Scope ổn định: cùng câu hỏi nhưng khác style → key khác."""
    return (
        f"{base}|a={agent}|p={persona}|m={motivation}|l={locale}"
    )


class SemanticCache:
    def __init__(self, redis_client) -> None:
        self._redis = redis_client
        self._settings = get_settings()

    def _exact_key(self, query: str, scope: str) -> str:
        h = hashlib.sha256(query.strip().lower().encode("utf-8")).hexdigest()
        return f"{_EXACT_PREFIX}{scope}:{h}"

    def exact_key_for(
        self,
        query: str,
        *,
        persona: str = "FriendlyBuddy",
        motivation: str = "Supportive",
        locale: str = "vi",
        agent: str = "*",
        scope: str = "global",
    ) -> str:
        return self._exact_key(
            query,
            style_scope(
                persona=persona,
                motivation=motivation,
                locale=locale,
                agent=agent,
                base=scope,
            ),
        )

    async def get(
        self,
        query: str,
        *,
        scope: str = "global",
        persona: str = "FriendlyBuddy",
        motivation: str = "Supportive",
        locale: str = "vi",
        agent: str = "*",
    ) -> str | None:
        if not self._settings.semantic_cache_enabled:
            return None
        styled = style_scope(
            persona=persona,
            motivation=motivation,
            locale=locale,
            agent=agent,
            base=scope,
        )
        exact = await self._redis.get(self._exact_key(query, styled))
        if exact:
            return exact.decode() if isinstance(exact, bytes) else str(exact)
        if not self._settings.semantic_cache_vector_enabled:
            return None
        q_emb = await embed_text(query)
        ids = await self._redis.zrevrange(f"{_INDEX_KEY}:{styled}", 0, 200)
        best, best_sim = None, 0.0
        for raw_id in ids:
            rid = raw_id.decode() if isinstance(raw_id, bytes) else raw_id
            raw = await self._redis.get(f"{_ENTRY_PREFIX}{rid}")
            if not raw:
                continue
            entry = json.loads(raw)
            sim = cosine(q_emb, entry["embedding"])
            if sim > best_sim:
                best, best_sim = entry, sim
        if best and best_sim >= self._settings.semantic_cache_threshold:
            return best["response"]
        return None

    async def put(
        self,
        query: str,
        response: str,
        *,
        scope: str = "global",
        persona: str = "FriendlyBuddy",
        motivation: str = "Supportive",
        locale: str = "vi",
        agent: str = "*",
    ) -> None:
        if not self._settings.semantic_cache_enabled:
            return
        styled = style_scope(
            persona=persona,
            motivation=motivation,
            locale=locale,
            agent=agent,
            base=scope,
        )
        ttl = self._settings.semantic_cache_ttl_seconds
        await self._redis.set(self._exact_key(query, styled), response, ex=ttl)
        if not self._settings.semantic_cache_vector_enabled:
            return
        emb = await embed_text(query)
        rid = f"{int(time.time()*1000)}"
        entry = {"query": query, "response": response, "embedding": emb}
        await self._redis.set(f"{_ENTRY_PREFIX}{rid}", json.dumps(entry), ex=ttl)
        await self._redis.zadd(f"{_INDEX_KEY}:{styled}", {rid: time.time()})
        await self._redis.expire(f"{_INDEX_KEY}:{styled}", ttl)
