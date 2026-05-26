"""In-process idempotency store (dev/single-instance). C# uses Redis for durable dedup."""

from __future__ import annotations

import asyncio
import time
from typing import Protocol


class IdempotencyStore(Protocol):
    async def exists(self, key: str) -> bool: ...

    async def mark(self, key: str, *, ttl_sec: int) -> None: ...


class InMemoryIdempotencyStore:
    def __init__(self) -> None:
        self._keys: dict[str, float] = {}
        self._lock = asyncio.Lock()

    async def exists(self, key: str) -> bool:
        async with self._lock:
            self._purge_expired()
            return key in self._keys

    async def mark(self, key: str, *, ttl_sec: int = 86_400) -> None:
        async with self._lock:
            self._purge_expired()
            self._keys[key] = time.monotonic() + ttl_sec

    def _purge_expired(self) -> None:
        now = time.monotonic()
        expired = [k for k, exp in self._keys.items() if exp <= now]
        for k in expired:
            del self._keys[k]
