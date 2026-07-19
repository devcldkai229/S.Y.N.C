"""Unit tests — tool registry."""
from __future__ import annotations

from app.tools.catalog import TOOL_REGISTRY, tools_for_agent, tool_schemas


def test_all_agents_have_tools():
    for agent in ("coach", "nutrition", "workout", "commerce", "insight"):
        names = tools_for_agent(agent)
        assert names, f"{agent} should have tools"
        for n in names:
            assert n in TOOL_REGISTRY


def test_workout_has_roadmap_tools():
    names = tools_for_agent("workout")
    for required in (
        "get_active_roadmap",
        "get_roadmap_sessions",
        "schedule_roadmap_session",
        "update_roadmap",
        "search_exercises",
        "get_exercise_detail",
        "get_exercise_media",
    ):
        assert required in names


def test_get_exercise_detail_accepts_query_or_id():
    detail = TOOL_REGISTRY["get_exercise_detail"]
    props = detail.parameters.get("properties", {})
    assert "exercise_id" in props
    assert "query" in props
    assert "slug" in props
    assert detail.parameters.get("required") in (None, [])


def test_vision_tool_hidden_when_disabled(monkeypatch):
    from app.config import get_settings

    monkeypatch.setattr(get_settings(), "vision_enabled", False)
    names = tools_for_agent("nutrition")
    assert "estimate_meal_from_photo" not in names
