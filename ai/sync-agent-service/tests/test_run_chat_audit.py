"""Unit tests cho chat audit runner (không gọi AI thật)."""

from __future__ import annotations

import json
from unittest.mock import MagicMock

import httpx

from tests.chat_batteries import BATTERIES
from tests.run_chat_audit import (
    _consume_sse_stream,
    _expected_intent,
    _format_tool_results,
    _render_turn_block,
    _session_id_for_item,
    _summary_lines,
    _turn_to_json,
    TurnResult,
)


def test_batteries_have_all_categories():
    expected = {
        "Coach",
        "Workout",
        "Nutrition",
        "Commerce",
        "Insight",
        "Ambiguous",
        "Multiturn",
        "Guardrail",
    }
    assert set(BATTERIES.keys()) == expected
    assert sum(len(v) for v in BATTERIES.values()) == 61


def test_multiturn_session_groups():
    sessions: dict[str, str] = {}
    ts = "20260701-1400"
    items = BATTERIES["Multiturn"]
    sid_a1 = _session_id_for_item("Multiturn", items[0], ts, sessions)
    sid_a2 = _session_id_for_item("Multiturn", items[1], ts, sessions)
    sid_b1 = _session_id_for_item("Multiturn", items[2], ts, sessions)
    sid_b2 = _session_id_for_item("Multiturn", items[3], ts, sessions)
    assert sid_a1 == sid_a2
    assert sid_b1 == sid_b2
    assert sid_a1 != sid_b1
    assert "Multiturn-A-" in sid_a1
    assert "Multiturn-B-" in sid_b1


def test_consume_sse_stream_tokens_and_final():
    tool_results = [
        {
            "tool": "get_workout_schedule",
            "args": {"date_label": "today"},
            "result": {"items": [{"sessionTitle": "Audit Session"}]},
        }
    ]
    body = (
        "event: token\n"
        "data: Hel\n\n"
        "event: token\n"
        "data: lo\n\n"
        'event: final\n'
        'data: {"type":"final","text":"Hello world","intent":"coach","tier":"small",'
        '"tools":["get_workout_schedule"],'
        f'"tool_results":{json.dumps(tool_results, ensure_ascii=False)}}}\n\n'
    )
    response = MagicMock(spec=httpx.Response)
    response.iter_lines = lambda: iter(body.splitlines())

    answer, meta = _consume_sse_stream(response, started_at=0.0)
    assert answer == "Hello world"
    assert meta["intent"] == "coach"
    assert meta["tier"] == "small"
    assert meta["tools"] == ["get_workout_schedule"]
    assert meta["tool_results"] == tool_results


def test_expected_intent_warning_mapping():
    assert _expected_intent("Workout", 5) == "workout"
    assert _expected_intent("Ambiguous", 29) == "nutrition"
    assert _expected_intent("Multiturn", "B1") == "commerce"


def test_summary_median_p95():
    results = [
        TurnResult(id=1, question="a", expected="e", total_ms=1000, status="OK"),
        TurnResult(id=2, question="b", expected="e", total_ms=2000, status="OK"),
        TurnResult(id=3, question="c", expected="e", total_ms=3000, status="OK"),
        TurnResult(id=4, question="d", expected="e", status="ERROR"),
    ]
    summary = "\n".join(_summary_lines(results))
    assert "Tổng câu     : 4" in summary
    assert "ERROR        : 1" in summary
    assert "Latency median" in summary


def test_turn_to_json_serializable():
    turn = TurnResult(
        id=12,
        question="hom nay an gi",
        expected="nutrition",
        intent="nutrition",
        tier="mid",
        tools=["get_nutrition_targets"],
        tool_results=[
            {
                "tool": "get_nutrition_targets",
                "args": {},
                "result": {"targetProteinGram": 150},
            }
        ],
        answer="Gợi ý món",
    )
    raw = json.dumps(_turn_to_json(turn), ensure_ascii=False)
    assert "get_nutrition_targets" in raw
    assert "targetProteinGram" in raw


def test_format_tool_results_truncate():
    long_result = {"data": "x" * 3000}
    lines = _format_tool_results(
        [{"tool": "search_food", "args": {"query": "chicken"}, "result": long_result}],
        max_chars=100,
    )
    joined = "\n".join(lines)
    assert "--- Kết quả tools ---" in joined
    assert "[1] search_food" in joined
    assert "… (truncated)" in joined


def test_render_turn_block_shows_tool_results():
    turn = TurnResult(
        id=5,
        question="hom nay tap bai gi vay",
        expected="workout",
        intent="workout",
        tier="mid",
        tools=["get_workout_schedule"],
        tool_results=[
            {
                "tool": "get_workout_schedule",
                "args": {"date_label": "today"},
                "result": {"items": [{"sessionTitle": "Audit Session"}]},
            }
        ],
        answer="Hôm nay bạn có buổi tập Audit Session.",
    )
    block = "\n".join(_render_turn_block("Workout", turn))
    assert "--- Kết quả tools ---" in block
    assert "[1] get_workout_schedule" in block
    assert "Audit Session" in block
    assert "--- Trả lời AI ---" in block
