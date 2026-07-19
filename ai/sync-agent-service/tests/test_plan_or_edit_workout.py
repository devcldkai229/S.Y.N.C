"""Unit tests — plan_or_edit_workout helpers (horizon/slots, exercise resolve, alias)."""
from __future__ import annotations

from datetime import date
from unittest.mock import AsyncMock, patch

import pytest

from app.tools.local import (
    _ZERO_GUID,
    assemble_workout_plan_context,
    generate_week_plan,
    plan_or_edit_workout,
    resolve_exercise_ids,
    resolve_plan_window,
)
from app.tools.catalog import AGENT_TOOLS, TOOL_REGISTRY
from app.tools.context import ToolRunContext


def test_resolve_slots_tonight_and_tomorrow():
    today = date(2026, 7, 12)
    window = resolve_plan_window(
        horizon="slots",
        target_slots=[
            {"date": "2026-07-12", "time_of_day": "toi"},
            {"date": "2026-07-13", "time_of_day": "tối"},
        ],
        today=today,
    )
    assert window["horizon"] == "slots"
    assert window["from_date"] == "2026-07-12"
    assert window["to_date"] == "2026-07-13"
    assert window["slots"] == [
        {"date": "2026-07-12", "time": "19:30"},
        {"date": "2026-07-13", "time": "19:30"},
    ]
    assert window["suggested_session_count"] == 2


def test_resolve_today_and_next_n_days():
    today = date(2026, 7, 12)
    w1 = resolve_plan_window(horizon="today", today=today)
    assert w1["from_date"] == w1["to_date"] == "2026-07-12"
    w2 = resolve_plan_window(horizon="next_n_days", days=3, today=today)
    assert w2["from_date"] == "2026-07-12"
    assert w2["to_date"] == "2026-07-14"


def test_resolve_week_uses_current_monday_when_in_week():
    # Sunday 2026-07-12 → Monday of that week is 2026-07-06
    today = date(2026, 7, 12)
    w = resolve_plan_window(horizon="week", today=today)
    assert w["from_date"] == "2026-07-06"
    assert w["to_date"] == "2026-07-12"


def test_catalog_has_plan_or_edit_workout():
    assert "plan_or_edit_workout" in TOOL_REGISTRY
    assert "plan_or_edit_workout" in AGENT_TOOLS["workout"]
    assert "generate_week_plan" in AGENT_TOOLS["workout"]


@pytest.mark.asyncio
async def test_resolve_exercise_ids_replaces_zero_guid():
    sessions = [{
        "date": "2026-07-12",
        "time": "19:30",
        "sessionTitle": "Upper",
        "sessionType": "Strength",
        "executionBlocks": [
            {"order": 1, "exerciseId": _ZERO_GUID, "exerciseName": "Bench Press", "targetSets": 3, "targetReps": 8},
        ],
    }]

    async def fake_search(user_id, **kwargs):
        return {"items": [{"id": "11111111-1111-1111-1111-111111111111", "name": "Bench Press"}]}

    with patch("app.tools.local.dotnet.search_exercises", AsyncMock(side_effect=fake_search)):
        out = await resolve_exercise_ids("user-1", sessions)

    assert out[0]["executionBlocks"][0]["exerciseId"] == "11111111-1111-1111-1111-111111111111"
    assert out[0]["executionBlocks"][0]["exerciseId"] != _ZERO_GUID


@pytest.mark.asyncio
async def test_assemble_bundle_has_required_keys():
    ctx = ToolRunContext(user_id="u1", state={
        "user_snapshot": {
            "gender": "Male",
            "heightCm": 175,
            "currentWeightKg": 70,
            "targetWeightKg": 68,
            "injuries": ["shoulder"],
            "medications": [],
        },
    })
    window = {"horizon": "today", "from_date": "2026-07-12", "to_date": "2026-07-12", "slots": [], "suggested_session_count": 1}

    with patch("app.tools.local.dotnet.get_active_roadmap", AsyncMock(return_value={
        "id": "r1", "fitnessGoal": "LoseFat", "currentPhase": "Foundation",
        "allowAiReschedule": True, "allowAiIntensityAdjustment": True, "allowAiRecoveryDeload": True,
        "targetWeightKg": 68, "targetFatPercentage": 15,
    })), patch("app.tools.local.dotnet.get_recovery_status", AsyncMock(return_value={
        "currentRecoveryScore": 72, "fatigueLevel": 4, "muscleSorenessScore": 3,
        "cnsFatigueScore": 2, "recommendedTrainingIntensity": "Moderate", "recommendedWorkoutDuration": 45,
    })), patch("app.tools.local.dotnet.get_workout_executions_range", AsyncMock(return_value={
        "items": [{
            "startedAt": "2026-07-11T10:00:00Z",
            "sessionId": "s1",
            "completionRate": 100,
            "perceivedDifficulty": 6,
            "energyLevelBefore": 7,
            "energyLevelAfter": 5,
            "caloriesBurned": 300,
            "actualDurationMinutes": 40,
            "skippedExercises": [],
            "sets": [{"exerciseId": "e1", "setNumber": 1, "targetReps": 10, "actualReps": 10, "weightKg": 40, "rir": 2, "formScore": 8}],
        }],
    })):
        bundle = await assemble_workout_plan_context(ctx, window=window, mode="create")

    assert "roadmap" in bundle and bundle["roadmap"]["fitnessGoal"] == "LoseFat"
    assert "biometrics" in bundle and bundle["biometrics"]["heightCm"] == 175
    assert "recovery" in bundle and bundle["recovery"]["fatigueLevel"] == 4
    assert "executions_last_7_days" in bundle
    assert len(bundle["executions_last_7_days"]) == 1
    assert bundle["executions_last_7_days"][0]["sets"]
    assert "constraints" in bundle and "shoulder" in bundle["constraints"]["injuries"]


@pytest.mark.asyncio
async def test_generate_week_plan_alias_calls_plan_or_edit():
    ctx = ToolRunContext(user_id="u1", state={"user_snapshot": {}})
    with patch(
        "app.tools.local.plan_or_edit_workout",
        AsyncMock(return_value={"status": "pending_confirmation", "mode": "create"}),
    ) as mocked:
        result = await generate_week_plan(ctx, roadmap_id="r1", week_start_date="2026-07-13", reason="test")
    assert result["status"] == "pending_confirmation"
    mocked.assert_awaited_once()
    kwargs = mocked.await_args.kwargs
    assert kwargs["horizon"] == "week"
    assert kwargs["mode"] == "create"
    assert kwargs["roadmap_id"] == "r1"
