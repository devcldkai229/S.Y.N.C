"""User-local calendar helpers for tools (default Asia/Ho_Chi_Minh)."""
from __future__ import annotations

from datetime import date, datetime
from typing import Any, Mapping
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

DEFAULT_TZ = "Asia/Ho_Chi_Minh"


def resolve_tz_name(state_or_ctx: Any = None, explicit: str | None = None) -> str:
    """Prefer explicit → state.user_timezone → default VN."""
    if explicit and str(explicit).strip():
        return str(explicit).strip()
    state: Mapping[str, Any] | None = None
    if state_or_ctx is None:
        state = None
    elif isinstance(state_or_ctx, Mapping):
        state = state_or_ctx
    else:
        state = getattr(state_or_ctx, "state", None)
    if isinstance(state, Mapping):
        tz = state.get("user_timezone") or state.get("timezone")
        if tz and str(tz).strip():
            return str(tz).strip()
    return DEFAULT_TZ


def zoneinfo(tz_name: str | None = None) -> ZoneInfo:
    name = (tz_name or DEFAULT_TZ).strip() or DEFAULT_TZ
    try:
        return ZoneInfo(name)
    except ZoneInfoNotFoundError:
        return ZoneInfo(DEFAULT_TZ)


def local_today(state_or_ctx: Any = None, *, tz_name: str | None = None) -> date:
    return datetime.now(zoneinfo(resolve_tz_name(state_or_ctx, tz_name))).date()


def local_now_iso(state_or_ctx: Any = None, *, tz_name: str | None = None) -> str:
    return datetime.now(zoneinfo(resolve_tz_name(state_or_ctx, tz_name))).isoformat(timespec="seconds")
