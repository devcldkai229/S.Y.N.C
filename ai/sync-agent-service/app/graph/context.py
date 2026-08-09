"""Context loader — nạp user_snapshot (biometrics + AIContextProfile).

Redis cache TTL giảm gọi IAM mỗi turn; de-identify trước khi vào prompt.
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from app.config import get_settings
from app.deps import get_redis
from app.observability import metrics
from app.observability.flow_log import flow
from app.state import SyncAgentState
from app.tools import dotnet


_DEFAULT_TZ = "Asia/Ho_Chi_Minh"


def _local_now(tz_name: str = _DEFAULT_TZ) -> str:
    """Trả về thời gian hiện tại theo múi giờ người dùng, ISO-8601."""
    try:
        tz = ZoneInfo(tz_name)
    except ZoneInfoNotFoundError:
        tz = ZoneInfo(_DEFAULT_TZ)
    return datetime.now(tz).isoformat(timespec="seconds")

_CONTEXT_CACHE_VERSION = "v3"

# Field an toàn để đưa vào prompt (không chứa PII định danh trực tiếp).
_SAFE_FIELDS = (
    "fitnessGoal", "experienceLevel", "activityLevel", "gender",
    "currentWeightKg", "targetWeightKg", "heightCm",
    "currentBodyFatPercentage", "goalBodyFatPercentage", "muscleMassKg",
    "workoutLocationPreference", "baseTDEE", "bmr",
    "dailyProteinTargetGram", "dailyCarbTargetGram", "dailyFatTargetGram",
    "dailyCalorieTarget", "targetsManagedByEngine", "targetsAdjustedAtUtc",
    "agentPersona", "motivationStyle", "allergies", "dislikedFoods",
    "injuries", "medications",
    "adherenceScore", "burnoutRiskScore", "recoveryScore", "maxAutoOrderLimitPerOrder",
    "subscriptionTier",
)


def _deidentify(raw: dict[str, Any]) -> dict[str, Any]:
    return {k: raw.get(k) for k in _SAFE_FIELDS if k in raw}


def _snapshot_cache_key(user_id: str) -> str:
    return f"ai:context:snapshot:{_CONTEXT_CACHE_VERSION}:{user_id}"


async def _cache_get_snapshot(user_id: str) -> dict[str, Any] | None:
    s = get_settings()
    if not s.context_snapshot_cache_enabled:
        return None
    r = get_redis()
    if r is None:
        return None
    try:
        raw = await r.get(_snapshot_cache_key(user_id))
        if raw:
            data = json.loads(raw)
            return data if isinstance(data, dict) else None
    except Exception:  # pragma: no cover
        return None
    return None


async def _cache_put_snapshot(user_id: str, snapshot: dict[str, Any]) -> None:
    s = get_settings()
    if not s.context_snapshot_cache_enabled:
        return
    r = get_redis()
    if r is None:
        return
    try:
        await r.set(
            _snapshot_cache_key(user_id),
            json.dumps(snapshot, ensure_ascii=False),
            ex=s.context_snapshot_cache_ttl_seconds,
        )
    except Exception:  # pragma: no cover
        pass


async def invalidate_user_snapshot_cache(user_id: str) -> None:
    """Drop Redis context cache after weigh-in / apply-targets so next turn sees fresh IAM."""
    s = get_settings()
    if not s.context_snapshot_cache_enabled:
        return
    r = get_redis()
    if r is None:
        return
    try:
        await r.delete(_snapshot_cache_key(user_id))
    except Exception:  # pragma: no cover
        pass


async def refresh_user_snapshot(state: dict[str, Any] | SyncAgentState) -> dict[str, Any]:
    """Invalidate cache, re-fetch IAM snapshot, write into state. Soft-fails to {}."""
    user_id = str(state.get("user_id") or "")
    if not user_id:
        return {}
    await invalidate_user_snapshot_cache(user_id)
    try:
        raw = await dotnet.get_user_snapshot(user_id)
        snapshot = _deidentify(raw if isinstance(raw, dict) else {})
    except Exception:  # pragma: no cover
        snapshot = {}
    if snapshot:
        await _cache_put_snapshot(user_id, snapshot)
    # Mutable ToolRunContext.state / SyncAgentState dict
    if isinstance(state, dict):
        state["user_snapshot"] = snapshot
    return snapshot


def _snapshot_state(
    snapshot: dict[str, Any],
    state: SyncAgentState,
    *,
    raw: dict[str, Any] | None = None,
) -> dict[str, Any]:
    # Source of truth = IAM snapshot; JWT/default only as fallback.
    iam_persona = snapshot.get("agentPersona") or snapshot.get("AgentPersona")
    iam_motivation = snapshot.get("motivationStyle") or snapshot.get("MotivationStyle")
    prev_persona = state.get("persona", "FriendlyBuddy")
    prev_motivation = state.get("motivation_style", "Supportive")
    persona = iam_persona or prev_persona or "FriendlyBuddy"
    motivation = iam_motivation or prev_motivation or "Supportive"
    if iam_persona and prev_persona and iam_persona != prev_persona:
        flow(
            f"Persona — ưu tiên IAM={iam_persona} (bỏ JWT/default={prev_persona})",
            indent=3,
        )
    if iam_motivation and prev_motivation and iam_motivation != prev_motivation:
        flow(
            f"Motivation — ưu tiên IAM={iam_motivation} (bỏ JWT/default={prev_motivation})",
            indent=3,
        )
    user_tz = state.get("user_timezone") or _DEFAULT_TZ
    tier = state.get("subscription_tier")
    if not tier and raw:
        tier = raw.get("subscriptionTier") or raw.get("SubscriptionTier")
    out: dict[str, Any] = {
        "user_snapshot": snapshot,
        "persona": persona,
        "motivation_style": motivation,
        "current_datetime": _local_now(user_tz),
        "user_timezone": user_tz,
    }
    if tier:
        out["subscription_tier"] = str(tier)
    return out


async def load_context(state: SyncAgentState) -> dict[str, Any]:
    user_tz = state.get("user_timezone") or _DEFAULT_TZ
    if state.get("user_snapshot"):
        flow("Context — dùng snapshot có sẵn trong state (resume)", indent=3)
        snap = state.get("user_snapshot") or {}
        # Re-sync persona/motivation from snapshot every turn (IAM wins).
        patch = {
            "current_datetime": _local_now(user_tz),
        }
        iam_persona = snap.get("agentPersona") or snap.get("AgentPersona")
        iam_motivation = snap.get("motivationStyle") or snap.get("MotivationStyle")
        prev = state.get("persona")
        if iam_persona:
            if prev and prev != iam_persona:
                flow(
                    f"Persona — resume sync IAM={iam_persona} (was {prev})",
                    indent=3,
                )
            patch["persona"] = iam_persona
        if iam_motivation:
            patch["motivation_style"] = iam_motivation
        return patch

    user_id = state["user_id"]

    with metrics.time_load_context("cache"):
        cached = await _cache_get_snapshot(user_id)
    if cached is not None:
        metrics.inc_context_cache_hit()
        flow(f"Context — Redis cache HIT | {len(cached)} field | user_id={user_id}", indent=3)
        return _snapshot_state(cached, state)

    flow(f"Context — gọi IAM lấy snapshot user_id={user_id}", indent=3)
    try:
        with metrics.time_load_context("iam"):
            raw = await dotnet.get_user_snapshot(user_id)
    except Exception:  # pragma: no cover — service down -> coaching vẫn chạy degrade
        flow("Context — IAM lỗi / không phản hồi → snapshot rỗng", indent=3)
        return {
            "user_snapshot": {},
            "guardrail_flags": [*state.get("guardrail_flags", []), "context_unavailable"],
        }

    snapshot = _deidentify(raw if isinstance(raw, dict) else {})
    await _cache_put_snapshot(user_id, snapshot)
    persona = snapshot.get("agentPersona") or state.get("persona", "FriendlyBuddy")
    flow(f"Context — đã nạp {len(snapshot)} field an toàn | persona={persona}", indent=3)
    return _snapshot_state(snapshot, state, raw=raw if isinstance(raw, dict) else None)
