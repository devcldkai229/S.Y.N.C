"""AllowAiReschedule gate helpers for plan_or_edit_workout."""
from __future__ import annotations

from app.tools.local import _enable_ai_reschedule_pending, _roadmap_allows_ai_reschedule


def test_roadmap_allows_ai_reschedule_true_false():
    assert _roadmap_allows_ai_reschedule({"allowAiReschedule": True}) is True
    assert _roadmap_allows_ai_reschedule({"AllowAiReschedule": True}) is True
    assert _roadmap_allows_ai_reschedule({"allowAiReschedule": False}) is False
    assert _roadmap_allows_ai_reschedule({}) is False
    assert _roadmap_allows_ai_reschedule(None) is False


def test_enable_pending_has_staged_plan():
    pending = _enable_ai_reschedule_pending(
        action_id="a1",
        roadmap_id="rid",
        summary="Buổi Upper 3x8",
        staged={"mode": "create", "sessions": [{"sessionTitle": "Upper"}]},
    )
    assert pending["type"] == "enable_ai_reschedule"
    assert pending["roadmap_id"] == "rid"
    assert pending["staged_plan"]["mode"] == "create"
    assert "Cho phép" in pending["summary"] or "cho phép" in pending["summary"].lower()


def test_plan_or_edit_pending_type():
    from app.tools.local import _plan_or_edit_workout_pending

    pending = _plan_or_edit_workout_pending(
        action_id="a2",
        roadmap_id="rid",
        summary="Lịch hôm nay",
        staged={"mode": "create", "sessions": [{"sessionTitle": "Full Body"}], "roadmap_id": "rid"},
    )
    assert pending["type"] == "plan_or_edit_workout"
    assert pending["mode"] == "create"
    assert pending["sessions"]
    assert pending["staged_plan"]["mode"] == "create"
