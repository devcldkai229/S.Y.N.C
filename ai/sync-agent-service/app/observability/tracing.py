"""Tracing qua Langfuse (tùy chọn). Mặc định TẮT — dùng flow_log console khi dev.

Trả callback handler để truyền vào LangGraph config. Nếu Langfuse tắt -> no-op.
"""
from __future__ import annotations

from functools import lru_cache
from typing import Any

from app.config import get_settings


@lru_cache(maxsize=1)
def _langfuse_handler() -> Any | None:
    s = get_settings()
    if not s.langfuse_enabled:
        return None
    if not s.langfuse_public_key:
        return None
    try:
        from langfuse.callback import CallbackHandler

        return CallbackHandler(
            public_key=s.langfuse_public_key,
            secret_key=s.langfuse_secret_key,
            host=s.langfuse_host,
        )
    except Exception:  # pragma: no cover
        return None


def trace_config(user_id: str, session_id: str, extra: dict[str, Any] | None = None) -> dict[str, Any]:
    """Tạo `config` cho graph.ainvoke/astream kèm callbacks + metadata."""
    cfg: dict[str, Any] = {
        "configurable": {"thread_id": session_id},
        "metadata": {"user_id": user_id, "session_id": session_id, **(extra or {})},
    }
    handler = _langfuse_handler()
    if handler is not None:
        cfg["callbacks"] = [handler]
    return cfg
