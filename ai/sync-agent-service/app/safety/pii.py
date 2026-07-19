"""Phát hiện & che PII trước khi context rời hạ tầng ra cloud LLM.

Patterns tập trung ở đây để dễ mở rộng (production có thể thay bằng Presidio/NER).
Tối ưu cho định dạng Việt Nam: SĐT VN, email, CMND/CCCD, số thẻ.
"""
from __future__ import annotations

import re

# Định dạng phổ biến tại VN. Mở rộng/điều chỉnh tại một nơi duy nhất.
PII_PATTERNS: dict[str, re.Pattern[str]] = {
    "phone": re.compile(r"(?:\+?84|0)(?:\d[ .-]?){8,10}\d"),
    "email": re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+"),
    "national_id": re.compile(r"\b\d{9}\b|\b\d{12}\b"),     # CMND(9)/CCCD(12)
    "card": re.compile(r"\b(?:\d[ -]?){13,19}\b"),          # số thẻ
}


def scrub_pii(text: str) -> tuple[str, list[str]]:
    """Trả (text đã che, danh sách cờ pii:<loại>). Không phá vỡ nếu rỗng."""
    if not text:
        return text, []
    flags: list[str] = []
    out = text
    for label, pat in PII_PATTERNS.items():
        if pat.search(out):
            flags.append(f"pii:{label}")
            out = pat.sub(f"[{label.upper()}]", out)
    return out, flags
