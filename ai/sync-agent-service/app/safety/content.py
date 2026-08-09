"""Kiểm tra an toàn nội dung ĐẦU RA (wellbeing) — chống lời khuyên gây hại.

Heuristic gom một nơi; production nên bổ sung safety model. Hỗ trợ VN có/không dấu.
"""
from __future__ import annotations

import re

from app.text_norm import strip_accents

# Mẫu chỉ dấu lời khuyên giảm cân/ăn kiêng cực đoan, nguy hiểm.
_UNSAFE_PATTERNS: tuple[str, ...] = (
    r"nhin an (hoan toan|ca ngay)",
    r"bo an (ca ngay|hoan toan)",
    r"giam \d+\s?kg trong \d+\s?(ngay|tuan)",
    r"thuoc giam can",
    r"(0|khong)\s?calo .* (ca ngay|moi ngay)",
)

_SAFE_REPLACEMENT_VI = (
    "Mình không thể đưa ra lời khuyên giảm cân cực đoan vì có thể ảnh hưởng sức khoẻ. "
    "Hãy đặt mục tiêu an toàn (~0.5–1kg/tuần) và cân nhắc tham khảo chuyên gia dinh dưỡng nhé."
)


def check_output_safety(text: str) -> tuple[str, bool]:
    """Trả (text an toàn, has_flag). Nếu vi phạm -> thay bằng thông điệp an toàn."""
    if not text:
        return text, False
    flat = strip_accents(text)
    if any(re.search(p, flat) for p in _UNSAFE_PATTERNS):
        return _SAFE_REPLACEMENT_VI, True
    return text, False
