"""RateLimiter unit tests with mocked Redis."""
from __future__ import annotations

import pytest
from fastapi import HTTPException

from app.api.ratelimit import RateLimiter


class _FakeRedis:
    def __init__(self, allowed: bool) -> None:
        self._allowed = allowed
        self._sha = "fake-sha"

    async def script_load(self, _script: str) -> str:
        return self._sha

    async def evalsha(self, _sha, _numkeys, *_args) -> int:
        return 1 if self._allowed else 0


@pytest.mark.asyncio
async def test_rate_limiter_allows_when_under_limit(monkeypatch):
    from app.config import get_settings

    monkeypatch.setattr(get_settings(), "rate_limit_enabled", True)
    monkeypatch.setattr(get_settings(), "rate_limit_free_per_min", 8)
    rl = RateLimiter(_FakeRedis(allowed=True))
    await rl.check("user-1", "Free")


@pytest.mark.asyncio
async def test_rate_limiter_raises_429_when_exceeded(monkeypatch):
    from app.config import get_settings

    monkeypatch.setattr(get_settings(), "rate_limit_enabled", True)
    monkeypatch.setattr(get_settings(), "rate_limit_free_per_min", 8)
    rl = RateLimiter(_FakeRedis(allowed=False))
    with pytest.raises(HTTPException) as exc:
        await rl.check("user-1", "Free")
    assert exc.value.status_code == 429
    assert "Premium" in str(exc.value.detail)


@pytest.mark.asyncio
async def test_rate_limiter_skips_when_disabled(monkeypatch):
    from app.config import get_settings

    monkeypatch.setattr(get_settings(), "rate_limit_enabled", False)
    rl = RateLimiter(_FakeRedis(allowed=False))
    await rl.check("user-1", "Free")
