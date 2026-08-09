"""Rate-limit theo SubscriptionTier dùng Redis sliding-window (token bucket).

Hạn mức/phút khớp ý tưởng Payment.SubscriptionPlan.AiUsageLimitPerMonth nhưng ở
mức thời gian thực (chống burst). Hạn mức tháng kiểm tra phía Payment khi cần.
"""
from __future__ import annotations

import time

from fastapi import HTTPException

from app.config import get_settings
from app.observability.flow_log import flow

# Lua script: sliding window counter — atomic, O(1).
_SLIDING_WINDOW_LUA = """
local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])
redis.call('ZREMRANGEBYSCORE', key, 0, now - window)
local count = redis.call('ZCARD', key)
if count >= limit then
  return 0
end
redis.call('ZADD', key, now, now .. '-' .. math.random())
redis.call('PEXPIRE', key, window)
return 1
"""


def _limit_for_tier(tier: str) -> int:
    s = get_settings()
    return {
        "Free": s.rate_limit_free_per_min,
        "Premium": s.rate_limit_premium_per_min,
        "Ultra": s.rate_limit_ultra_per_min,
    }.get(tier, s.rate_limit_free_per_min)


class RateLimiter:
    def __init__(self, redis_client) -> None:
        self._redis = redis_client
        self._sha: str | None = None

    async def _ensure_script(self) -> str:
        if self._sha is None:
            self._sha = await self._redis.script_load(_SLIDING_WINDOW_LUA)
        return self._sha

    async def check(self, user_id: str, tier: str) -> None:
        """Raise 429 nếu vượt hạn mức/phút."""
        if not get_settings().rate_limit_enabled:
            return
        limit = _limit_for_tier(tier)
        key = f"ai:rl:{user_id}"
        now_ms = int(time.time() * 1000)
        window_ms = 60_000
        try:
            sha = await self._ensure_script()
            allowed = await self._redis.evalsha(sha, 1, key, now_ms, window_ms, limit)
        except Exception:
            # Redis lỗi -> fail-open (không chặn người dùng vì hạ tầng), nhưng log.
            return
        if not allowed:
            flow(f"✗ Rate-limit — từ chối ({limit}/phút, gói {tier})", indent=1)
            raise HTTPException(
                status_code=429,
                detail="Đã đạt giới hạn chat/phút — nâng cấp Premium để tăng hạn mức.",
            )
