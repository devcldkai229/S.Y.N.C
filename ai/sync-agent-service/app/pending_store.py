"""Redis-backed pending confirm actions.

Chat turns reset graph `pending_actions` so UI chips do not re-fire. Confirmable
actions still need a durable lookup for ~30 minutes after SSE emit.
"""
from __future__ import annotations

import json
import logging
from typing import Any

from app.config import get_settings
from app.deps import get_redis

_log = logging.getLogger("sync-ai.pending")

_KEY_PREFIX = "ai:pending:"


def _key(user_id: str, session_id: str, action_id: str) -> str:
    return f"{_KEY_PREFIX}{user_id}:{session_id}:{action_id}"


async def save_pending(
    user_id: str,
    session_id: str,
    action: dict[str, Any],
) -> None:
    """Persist a pending_action JSON for confirm endpoint fallback."""
    action_id = str(action.get("action_id") or "").strip()
    if not action_id or not user_id or not session_id:
        return
    r = get_redis()
    if r is None:
        _log.warning("pending_store: redis unavailable, skip save action_id=%s", action_id)
        return
    ttl = int(get_settings().pending_action_ttl_seconds or 1800)
    try:
        await r.set(
            _key(user_id, session_id, action_id),
            json.dumps(action, ensure_ascii=False, default=str),
            ex=max(60, ttl),
        )
    except Exception:
        _log.exception("pending_store: save failed action_id=%s", action_id)


async def get_pending(
    user_id: str,
    session_id: str,
    action_id: str,
) -> dict[str, Any] | None:
    """Load pending action from Redis; returns None if missing/invalid."""
    if not action_id or not user_id or not session_id:
        return None
    r = get_redis()
    if r is None:
        return None
    try:
        raw = await r.get(_key(user_id, session_id, action_id))
    except Exception:
        _log.exception("pending_store: get failed action_id=%s", action_id)
        return None
    if not raw:
        return None
    if isinstance(raw, bytes):
        raw = raw.decode("utf-8", errors="replace")
    try:
        data = json.loads(raw)
    except Exception:
        return None
    return data if isinstance(data, dict) else None


async def delete_pending(
    user_id: str,
    session_id: str,
    action_id: str,
) -> None:
    if not action_id or not user_id or not session_id:
        return
    r = get_redis()
    if r is None:
        return
    try:
        await r.delete(_key(user_id, session_id, action_id))
    except Exception:
        _log.exception("pending_store: delete failed action_id=%s", action_id)
