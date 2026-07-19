"""Unit tests — edit intent forces targetSets; local today helper."""
from __future__ import annotations

from app.tools.local import apply_explicit_edit_overrides, format_sessions_prose
from app.tools.time_utils import DEFAULT_TZ, local_today, resolve_tz_name


def test_resolve_tz_defaults_vn():
    assert resolve_tz_name({}) == DEFAULT_TZ
    assert resolve_tz_name({"user_timezone": "Asia/Bangkok"}) == "Asia/Bangkok"


def test_local_today_returns_date():
    d = local_today({"user_timezone": "Asia/Ho_Chi_Minh"})
    assert d.isoformat()  # valid date


def test_apply_plank_one_set():
    sessions = [
        {
            "sessionTitle": "Full body",
            "executionBlocks": [
                {"exerciseName": "Squat", "targetSets": 3, "targetReps": 10},
                {"exerciseName": "Plank", "targetSets": 3, "targetReps": 30},
            ],
        }
    ]
    out = apply_explicit_edit_overrides(sessions, "Plank chỉ 1 set")
    plank = out[0]["executionBlocks"][1]
    squat = out[0]["executionBlocks"][0]
    assert plank["targetSets"] == 1
    assert squat["targetSets"] == 3


def test_format_sessions_prose_no_json_keys():
    text = format_sessions_prose(
        [
            {
                "date": "2026-07-13",
                "time": "07:00",
                "sessionTitle": "Upper",
                "estimatedDurationMinutes": 45,
                "executionBlocks": [
                    {"exerciseName": "Bench press", "targetSets": 3, "targetReps": 8, "targetWeightKg": 40},
                ],
            }
        ],
        window={"from_date": "2026-07-13", "to_date": "2026-07-13", "horizon": "today"},
        reason="Phù hợp mục tiêu BuildMuscle.",
    )
    assert "targetSets" not in text
    assert "{" not in text
    assert "Bench press" in text
    assert "3x8" in text
    assert "xác nhận" in text.lower() or "Xác nhận" in text
