"""Guard against nested planner JSON leaking into chat ToolMessages / SSE tags."""
from __future__ import annotations

from app.graph.toolrunner import (
    STREAM_FINAL_TAG,
    _config_with_stream_final_tag,
    _tool_message_content,
)


def test_stream_final_tag_merged():
    cfg = _config_with_stream_final_tag({"tags": ["agent"]})
    assert STREAM_FINAL_TAG in cfg["tags"]
    assert "agent" in cfg["tags"]


def test_stream_final_tag_when_config_none():
    cfg = _config_with_stream_final_tag(None)
    assert cfg["tags"] == [STREAM_FINAL_TAG]


def test_pending_confirmation_tool_message_is_prose():
    content = _tool_message_content(
        {
            "status": "pending_confirmation",
            "action_id": "act-1",
            "mode": "create",
            "message": "Buổi Upper · Bench 3x8 · Xác nhận nhé?",
            "sessions": [{"executionBlocks": [{"targetSets": 3}]}],
        }
    )
    assert "Buổi Upper" in content
    assert "pending_confirmation" in content
    assert "targetSets" not in content
    assert "executionBlocks" not in content
    assert "{" not in content


def test_other_tool_results_unchanged():
    assert _tool_message_content({"ok": True, "n": 1}) == str({"ok": True, "n": 1})
