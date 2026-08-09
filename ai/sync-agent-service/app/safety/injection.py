"""Phát hiện prompt-injection (heuristic nhiều lớp).

Lưu ý production: đây là LỚP PHÒNG THỦ ĐẦU, nên kết hợp với:
- Tách biệt data/instruction (nội dung RAG/đối tác đánh dấu untrusted).
- Allowlist + schema-validation cho tool-calls.
- (Khuyến nghị) classifier chuyên dụng cho injection.
Patterns gom một nơi, hỗ trợ tiếng Việt có dấu & không dấu.
"""
from __future__ import annotations

import re

from app.text_norm import strip_accents

# Cụm chỉ thị độc — so trên bản đã bỏ dấu để bắt cả tiếng Việt không dấu.
_INJECTION_PATTERNS: tuple[str, ...] = (
    r"ignore (all )?(previous|prior) instructions",
    r"disregard (the )?(above|system)",
    r"bo qua (cac )?(huong dan|chi dan|lenh)",
    r"quen (het )?(huong dan|nhung gi)",
    r"reveal (your )?(system )?prompt",
    r"in ra (he thong|huong dan) prompt",
    # "khoa" trần bắt nhầm "khóa học/khoa..." — chỉ khớp khi đi kèm ngữ cảnh bí mật.
    r"(show|tiet lo|reveal).*(api key|internal key|secret key|access token|khoa (bi mat|noi bo|he thong|api))",
    r"you are now",
    r"act as (a )?(dan|jailbreak)",
    r"bay gio ban la",
)


def detect_injection(text: str) -> bool:
    if not text:
        return False
    flat = strip_accents(text)
    return any(re.search(p, flat) for p in _INJECTION_PATTERNS)
