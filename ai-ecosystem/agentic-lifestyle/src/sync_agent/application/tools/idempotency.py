"""Deterministic idempotency keys for tool command publishing."""

from __future__ import annotations

import hashlib
from datetime import datetime, timezone


def build_idempotency_key(user_id: str, action: str, turn_timestamp: str) -> str:
    """
    SHA-256 hash of user_id + action + turn_timestamp (per Phase 5 spec).

    turn_timestamp should be stable for the entire voice turn (set once at pipeline start).
    """
    raw = f"{user_id.strip()}|{action.strip()}|{turn_timestamp.strip()}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def new_turn_timestamp() -> str:
    """ISO-8601 UTC timestamp for a new agent turn."""
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()
