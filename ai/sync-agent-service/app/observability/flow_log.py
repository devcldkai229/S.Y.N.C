"""Log luồng xử lý request AI ra console — dễ đọc khi debug (tiếng Việt).

Bật mặc định khi ENVIRONMENT=development hoặc FLOW_LOG_ENABLED=true.
Langfuse tắt thì đây là nguồn trace chính cho dev.
"""
from __future__ import annotations

import contextvars
import json
import sys
from typing import Any

_PREFIX = "[CYN-AI]"

_trace_id: contextvars.ContextVar[str | None] = contextvars.ContextVar("flow_trace_id", default=None)


def set_trace_id(trace_id: str | None) -> None:
    _trace_id.set(trace_id)


def get_trace_id() -> str | None:
    return _trace_id.get()


def _enabled() -> bool:
    from app.config import get_settings

    s = get_settings()
    return s.flow_log_enabled or s.environment == "development"


def _tid_suffix() -> str:
    tid = get_trace_id()
    return f" [{tid[:8]}]" if tid else ""


def flow(msg: str, *, indent: int = 0) -> None:
    if not _enabled():
        return
    pad = "  " * indent
    print(f"{_PREFIX}{_tid_suffix()} {pad}{msg}", file=sys.stdout, flush=True)


def flow_timing(label: str, elapsed_ms: int, *, indent: int = 0) -> None:
    """Log thời gian (ms) cho đo latency trước/sau tối ưu."""
    flow(f"⏱ {label}: {elapsed_ms}ms", indent=indent)


def flow_data(
    label: str,
    data: Any,
    *,
    indent: int = 1,
    max_len: int = 400,
) -> None:
    if not _enabled():
        return
    try:
        if isinstance(data, (dict, list)):
            text = json.dumps(data, ensure_ascii=False, default=str)
        else:
            text = str(data)
    except Exception:
        text = repr(data)
    if len(text) > max_len:
        text = text[:max_len] + "…"
    flow(f"{label}: {text}", indent=indent)


def flow_banner() -> None:
    if not _enabled():
        return
    from app.config import get_settings

    s = get_settings()
    langfuse = "BẬT" if s.langfuse_enabled and s.langfuse_public_key else "TẮT"
    print(
        f"\n{_PREFIX} ═══ SYNC AI Agent — log luồng xử lý (dev) ═══\n"
        f"{_PREFIX}   Môi trường: {s.environment} | Langfuse: {langfuse}\n"
        f"{_PREFIX}   DeepSeek + OpenAI | Redis: {s.redis_url}\n",
        file=sys.stdout,
        flush=True,
    )
