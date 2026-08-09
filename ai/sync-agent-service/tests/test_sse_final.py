"""SSE final payload + stream piece normalization."""
from __future__ import annotations

import json

from app.api.main import _normalize_stream_piece


def test_normalize_stream_piece_string():
    assert _normalize_stream_piece("hello") == "hello"


def test_normalize_stream_piece_multimodal_list():
    piece = [{"type": "text", "text": "Hel"}, {"type": "text", "text": "lo"}]
    assert _normalize_stream_piece(piece) == "Hello"


def test_final_payload_shape():
    payload = {
        "type": "final",
        "text": "Xin chào bạn!",
        "intent": "coach",
        "tier": "small",
        "tools": [],
        "requires_confirmation": False,
    }
    raw = json.dumps(payload, ensure_ascii=False)
    parsed = json.loads(raw)
    assert parsed["type"] == "final"
    assert parsed["text"] == "Xin chào bạn!"
