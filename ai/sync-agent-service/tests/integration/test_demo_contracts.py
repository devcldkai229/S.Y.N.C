"""Offline unit tests for demo_contracts validators (no .NET services)."""
from __future__ import annotations

from tests.integration.demo_contracts import (
    EXPECT_GAMIFICATION,
    EXPECT_MACRO_TARGETS,
    EXPECT_ROADMAP_ID,
    EXPECT_TODAY_SESSION_ID,
    EXPECT_WALLET_COINS,
    validate_contract,
    validate_fixture_extraction,
)


def test_gamification_contract_pass():
    result = {**EXPECT_GAMIFICATION, "longestStreak": 21, "achievementPoints": 520}
    assert validate_contract("get_gamification_status", result) == []


def test_gamification_contract_fail_level():
    result = {**EXPECT_GAMIFICATION, "currentLevel": 1}
    errors = validate_contract("get_gamification_status", result)
    assert any("currentLevel" in e for e in errors)


def test_roadmap_contract_pass():
    result = {
        "id": EXPECT_ROADMAP_ID,
        "roadmapName": "Demo Fat Loss 12W",
        "roadmapStatus": "Active",
        "currentWeightKg": 78,
        "targetWeightKg": 72,
    }
    assert validate_contract("get_active_roadmap", result) == []


def test_today_workout_contract_pass():
    result = {
        "hasWorkoutScheduledToday": True,
        "sessionId": EXPECT_TODAY_SESSION_ID,
        "todayWorkoutName": "Hôm nay: Upper Push + Core",
    }
    assert validate_contract("get_today_workout", result) == []


def test_daily_summary_contract_pass():
    result = {
        **EXPECT_MACRO_TARGETS,
        "waterIntakeMl": 1200,
        "mealsLoggedCount": 3,
        "consumedCalories": 1082,
    }
    assert validate_contract("get_daily_summary", result) == []


def test_wallet_contract_pass():
    result = {"coinBalance": EXPECT_WALLET_COINS, "currency": "COIN"}
    assert validate_contract("check_wallet", result) == []


def test_search_exercises_non_empty():
    result = {
        "items": [
            {"id": "ca59b5e8-62d8-48f2-8e8a-1d6cd1f37e90", "nameEn": "Push Up to Side Plank"},
        ],
    }
    assert validate_contract("search_exercises", result, kwargs={"query": "push"}) == []


def test_today_workout_scheduled_without_session_id():
    result = {
        "hasWorkoutScheduledToday": True,
        "sessionId": None,
        "todayWorkoutName": "Hôm nay: Upper Push + Core",
    }
    assert validate_contract("get_today_workout", result) == []


def test_fixture_extraction_today_workout_missing_session():
    errors = validate_fixture_extraction(
        "get_today_workout",
        {"hasWorkoutScheduledToday": False},
    )
    assert errors

def test_unknown_tool_returns_no_errors():
    assert validate_contract("handoff", {"ok": True}) == []
