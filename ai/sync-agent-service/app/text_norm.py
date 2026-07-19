"""Chuẩn hoá văn bản tiếng Việt — dùng chung cho intent fallback + safety.

Lưu ý quan trọng: ký tự 'đ/Đ' KHÔNG tách dấu qua Unicode NFD (nó là ký tự dựng sẵn,
không có canonical decomposition). Phải thay 'đ'->'d' thủ công, nếu không
"đặt" sẽ ra "đat" thay vì "dat" -> match từ khoá hỏng. Đây là lỗi kinh điển khi
xử lý tiếng Việt.
"""
from __future__ import annotations

import re
import unicodedata

_D_MAP = str.maketrans({"đ": "d", "Đ": "D"})


def has_vietnamese_diacritics(text: str) -> bool:
    """True nếu có dấu thanh/dấu phụ tiếng Việt (gồm cả 'đ')."""
    if "đ" in text or "Đ" in text:
        return True
    return any(unicodedata.category(c) == "Mn" for c in unicodedata.normalize("NFD", text))


def strip_accents(text: str) -> str:
    """Bỏ toàn bộ dấu tiếng Việt + chuyển đ->d, trả lowercase. 'Đặt' -> 'dat'."""
    text = text.translate(_D_MAP)
    nfkd = unicodedata.normalize("NFD", text)
    return "".join(c for c in nfkd if unicodedata.category(c) != "Mn").lower()


def word_in(text: str, keyword: str) -> bool:
    """Khớp keyword theo ranh giới từ (tránh 'an' lọt vào 'banh')."""
    return re.search(rf"(?<!\w){re.escape(keyword)}(?!\w)", text) is not None
