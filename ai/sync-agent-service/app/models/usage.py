"""Trích token usage thật từ phản hồi LLM (thay ước lượng char/4 tạm thời).

LangChain AIMessage thường có `usage_metadata` = {input_tokens, output_tokens,
total_tokens}. Một số provider trả trong response_metadata. Có fallback ước lượng
để không bao giờ vỡ.
"""
from __future__ import annotations

from typing import Any


def extract_token_usage(response: Any) -> tuple[int, int]:
    """Trả (input_tokens, output_tokens). Cố gắng đọc metadata thật trước."""
    meta = getattr(response, "usage_metadata", None)
    if isinstance(meta, dict):
        return int(meta.get("input_tokens", 0)), int(meta.get("output_tokens", 0))

    rmeta = getattr(response, "response_metadata", None)
    if isinstance(rmeta, dict):
        usage = rmeta.get("token_usage") or rmeta.get("usage") or {}
        if usage:
            return (
                int(usage.get("prompt_tokens", usage.get("input_tokens", 0))),
                int(usage.get("completion_tokens", usage.get("output_tokens", 0))),
            )
    return 0, 0


def approx_tokens(*texts: str) -> int:
    """Fallback ~4 ký tự/token khi không có metadata (đủ cho budget guard)."""
    return sum(len(t or "") for t in texts) // 4


def total_tokens(response: Any, *prompt_texts: str) -> int:
    """Tổng token của 1 lượt: ưu tiên metadata, fallback ước lượng."""
    inp, out = extract_token_usage(response)
    if inp or out:
        return inp + out
    output_text = getattr(response, "content", "") or ""
    return approx_tokens(*prompt_texts, output_text)
