"""Regression tests — bộ fix lõi từ phiên test thực tế (handoff narration,
stale pending, classifier fallback, intent routing, lỗi .NET đọc được,
GUID validation, chuẩn hoá payload roadmap)."""
from __future__ import annotations

from types import SimpleNamespace
from typing import Any

import httpx
import pytest

# ---------------------------------------------------------------------------
# A. Hop đã gọi handoff KHÔNG stream narration
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_handoff_hop_suppresses_narration(monkeypatch):
    from app.graph.agents import runner as runner_mod
    from app.state import initial_state

    streamed: list[str] = []

    async def fake_resolve(model, messages, impls, config=None, **kw):
        # Mô phỏng LLM gọi tool handoff trong tool phase.
        await impls["handoff"](target_agent="workout", reason="test")
        return messages

    async def fake_stream(model, messages, config=None, **kw):
        streamed.append("called")
        return "KHÔNG ĐƯỢC STREAM", None

    monkeypatch.setattr(runner_mod, "resolve_tool_calls", fake_resolve)
    monkeypatch.setattr(runner_mod, "stream_final_response", fake_stream)
    monkeypatch.setattr(runner_mod, "get_bound_tool_model", lambda *a, **k: object())
    monkeypatch.setattr(runner_mod, "get_chat_model", lambda *a, **k: object())

    state = initial_state(user_id="u1", session_id="s1")
    state["model_tier"] = "mid"

    out = await runner_mod.run_tool_agent(state, "coach", config=None)

    assert out.get("next_agent") == "workout"
    assert streamed == [], "hop handoff không được gọi stream_final_response"
    assert "KHÔNG ĐƯỢC STREAM" not in (out.get("final_response") or "")


@pytest.mark.asyncio
async def test_non_handoff_hop_still_streams(monkeypatch):
    from app.graph.agents import runner as runner_mod
    from app.state import initial_state

    async def fake_resolve(model, messages, impls, config=None, **kw):
        return messages

    async def fake_stream(model, messages, config=None, **kw):
        return "câu trả lời thật", None

    monkeypatch.setattr(runner_mod, "resolve_tool_calls", fake_resolve)
    monkeypatch.setattr(runner_mod, "stream_final_response", fake_stream)
    monkeypatch.setattr(runner_mod, "get_bound_tool_model", lambda *a, **k: object())
    monkeypatch.setattr(runner_mod, "get_chat_model", lambda *a, **k: object())

    state = initial_state(user_id="u1", session_id="s1")
    state["model_tier"] = "mid"

    out = await runner_mod.run_tool_agent(state, "coach", config=None)
    assert out.get("final_response") == "câu trả lời thật"
    assert not out.get("next_agent")


# ---------------------------------------------------------------------------
# C. Classifier: structured method theo provider (OpenAI json_schema / Ollama json_mode)
# ---------------------------------------------------------------------------


def _settings(openai_key: str, provider: str = "openai"):
    return SimpleNamespace(
        intent_classifier_provider=provider,
        intent_classifier_model="gpt-4o-mini",
        intent_classifier_max_tokens=200,
        openai_api_key=openai_key,
        ollama_base_url="http://localhost:11434",
    )


def test_classifier_effective_provider_returns_configured():
    from app.models.router import _classifier_effective_provider

    assert _classifier_effective_provider(_settings("sk-x", "openai")) == "openai"
    assert _classifier_effective_provider(_settings("", "ollama")) == "ollama"


def test_classifier_structured_method_matches_provider(monkeypatch):
    import app.models.router as router_mod

    monkeypatch.setattr(router_mod, "get_settings", lambda: _settings("", "ollama"))
    router_mod.get_classifier_structured_method.cache_clear()
    assert router_mod.get_classifier_structured_method() == "json_mode"

    monkeypatch.setattr(router_mod, "get_settings", lambda: _settings("sk-x", "openai"))
    router_mod.get_classifier_structured_method.cache_clear()
    assert router_mod.get_classifier_structured_method() == "json_schema"
    router_mod.get_classifier_structured_method.cache_clear()


# ---------------------------------------------------------------------------
# D. Intent routing: stats đa kỳ → insight; cart/tìm món → commerce
# ---------------------------------------------------------------------------


def test_keyword_nutrition_stats_routes_insight():
    from app.graph.intent import try_keyword_fast_path

    for text in (
        "thống kê dinh dưỡng 2 tuần gần đây của tôi nhé",
        "thong ke dinh duong thang nay",
        "xu hướng calo của mình dạo này",
    ):
        r = try_keyword_fast_path(text)
        assert r is not None, text
        assert r.agent == "insight", f"{text} -> {r.agent}"


def test_keyword_cart_and_find_dish_route_commerce():
    from app.graph.intent import try_keyword_fast_path

    for text in (
        "thêm món đó vào cart giúp mình",
        "them vao gio hang di",
        "tìm món ăn phù hợp với dinh dưỡng và mục tiêu của tôi",
        "gợi ý món khác đi",
    ):
        r = try_keyword_fast_path(text)
        assert r is not None, text
        assert r.agent == "commerce", f"{text} -> {r.agent}"


def test_keyword_co_ban_does_not_misroute():
    from app.graph.intent import try_keyword_fast_path

    # "cơ bản" (strip dấu = "co ban") không được kéo về commerce.
    r = try_keyword_fast_path("hướng dẫn cơ bản giúp mình")
    assert r is None


# ---------------------------------------------------------------------------
# F. Lỗi .NET đọc được + không retry 4xx
# ---------------------------------------------------------------------------


def _resp(status: int, body: Any) -> httpx.Response:
    req = httpx.Request("POST", "http://localhost:5118/api/internal/x")
    if isinstance(body, (dict, list)):
        return httpx.Response(status, json=body, request=req)
    return httpx.Response(status, text=str(body), request=req)


def test_extract_error_message_from_validation_factory():
    from app.tools.dotnet import _extract_error_message

    msg = _extract_error_message(_resp(400, {
        "message": "Validation failed.",
        "errors": {"sessionStatus": ["The value could not be parsed."]},
    }))
    assert "Validation failed." in msg
    assert "sessionStatus" in msg


def test_extract_error_message_plain_text_and_empty():
    from app.tools.dotnet import _extract_error_message

    assert "AI session edits are disabled" in _extract_error_message(
        _resp(400, {"message": "AI session edits are disabled for this roadmap."})
    )
    assert "HTTP 400" in _extract_error_message(_resp(400, ""))


def test_transient_predicate_skips_4xx_retries_5xx():
    from app.tools.dotnet import DotnetApiError, _is_transient

    e400 = DotnetApiError("bad", request=_resp(400, "").request, response=_resp(400, ""))
    e500 = DotnetApiError("boom", request=_resp(500, "").request, response=_resp(500, ""))
    assert _is_transient(e400) is False
    assert _is_transient(e500) is True
    assert _is_transient(httpx.ConnectTimeout("t")) is True
    assert _is_transient(ValueError("x")) is False


def test_readable_error_unwraps_retryerror_and_dotnet():
    from tenacity import RetryError
    from unittest.mock import Mock

    from app.tools.dotnet import DotnetApiError, readable_error

    inner = DotnetApiError(
        "Validation failed. | sessionStatus: bad",
        request=_resp(400, "").request,
        response=_resp(400, ""),
    )
    attempt = Mock()
    attempt.exception.return_value = inner
    wrapped = RetryError(attempt)

    msg = readable_error(wrapped)
    assert "RetryError" not in msg
    assert "Validation failed." in msg
    assert "400" in msg

    assert "timeout" in readable_error(httpx.ConnectTimeout("t")).lower() or \
        "kết nối" in readable_error(httpx.ConnectTimeout("t"))


def test_dotnet_error_still_catchable_as_httpstatuserror():
    from app.tools.dotnet import DotnetApiError

    err = DotnetApiError("x", request=_resp(429, "").request, response=_resp(429, ""))
    assert isinstance(err, httpx.HTTPStatusError)
    assert err.response.status_code == 429


# ---------------------------------------------------------------------------
# G. Chuẩn hoá payload update session
# ---------------------------------------------------------------------------


def test_norm_session_status_maps_variants():
    from app.tools.local import _norm_session_status

    assert _norm_session_status("Scheduled") == "Scheduled"
    assert _norm_session_status("in_progress") == "InProgress"
    assert _norm_session_status("IN PROGRESS") == "InProgress"
    assert _norm_session_status("completed") == "Completed"
    assert _norm_session_status("skipped") == "Skipped"
    # Giá trị lạ/None → Scheduled (tránh 400 enum của .NET).
    assert _norm_session_status("planned") == "Scheduled"
    assert _norm_session_status(None) == "Scheduled"


# ---------------------------------------------------------------------------
# M. ≥2 buổi cùng ngày → giờ khác nhau (planner hay đặt tất cả vào 19:30)
# ---------------------------------------------------------------------------


def test_spread_session_times_two_sessions_same_day():
    from app.tools.local import _spread_session_times

    sessions = [
        {"date": "2026-07-16", "time": "19:30", "sessionTitle": "Chính"},
        {"date": "2026-07-16", "time": "19:30", "sessionTitle": "Phụ"},
        {"date": "2026-07-17", "time": "19:30", "sessionTitle": "Ngày khác"},
    ]
    out = _spread_session_times(sessions)
    day1_times = [s["time"] for s in out if s["date"] == "2026-07-16"]
    assert len(set(day1_times)) == 2, "2 buổi cùng ngày phải khác giờ"
    assert out[0]["time"] == "19:30", "buổi đầu giữ giờ user thích"
    assert out[1]["time"] == "06:30", "buổi trùng giờ được gán slot còn trống"
    assert out[2]["time"] == "19:30", "ngày chỉ 1 buổi không bị đổi giờ"


def test_spread_session_times_fills_missing_time():
    from app.tools.local import _spread_session_times

    sessions = [
        {"date": "2026-07-16", "time": "", "sessionTitle": "A"},
        {"date": "2026-07-16", "sessionTitle": "B"},
    ]
    out = _spread_session_times(sessions)
    times = [s["time"] for s in out]
    assert len(set(times)) == 2
    assert all(t for t in times)


# ---------------------------------------------------------------------------
# Insight: vùng calo theo mục tiêu (adherence không còn ±10% ra 0%)
# ---------------------------------------------------------------------------


def test_goal_calorie_band_deficit_surplus_maintain():
    from app.tools.insight_stats import _goal_calorie_band, _goal_kind

    assert _goal_kind("LoseFat") == "deficit"
    assert _goal_kind("GainMuscle") == "surplus"
    assert _goal_kind("Maintain") == "maintain"

    lose = _goal_calorie_band("LoseFat", 2200)
    # Ăn thâm hụt ~300 (1900) phải nằm trong vùng đạt; ăn đúng 2200 thì KHÔNG.
    assert lose["band_min"] <= 1900 <= lose["band_max"]
    assert not (lose["band_min"] <= 2200 <= lose["band_max"])
    assert lose["encouraged"] == 1900

    gain = _goal_calorie_band("GainMuscle", 2200)
    assert gain["band_min"] <= 2450 <= gain["band_max"]
    assert gain["encouraged"] == 2450

    maintain = _goal_calorie_band("Maintain", 2000)
    assert maintain["band_min"] <= 2000 <= maintain["band_max"]
    assert not (maintain["band_min"] <= 1600 <= maintain["band_max"])


def test_eval_stats_query_routes_insight():
    from app.graph.intent import try_keyword_fast_path

    for text in (
        "dinh dưỡng mấy ngày nay của tôi thế nào rồi",
        "tuần này mình ăn uống ra sao",
        "nhận xét chế độ ăn của tôi đi",
        "đánh giá dinh dưỡng giúp mình",
    ):
        r = try_keyword_fast_path(text)
        assert r is not None, text
        assert r.agent == "insight", f"{text} -> {r.agent}"


def test_simple_nutrition_question_stays_nutrition():
    from app.graph.intent import try_keyword_fast_path

    # Hỏi số liệu 1 ngày cụ thể, KHÔNG đánh giá đa kỳ → vẫn nutrition.
    r = try_keyword_fast_path("hôm nay mình ăn được bao nhiêu calo")
    assert r is not None
    assert r.agent == "nutrition"


# ---------------------------------------------------------------------------
# "Đến hết tuần" + "k buổi/ngày": window và số buổi phải đúng yêu cầu
# ---------------------------------------------------------------------------


def test_rest_of_week_window_ends_on_sunday():
    from datetime import date

    from app.tools.local import resolve_plan_window

    # 2026-07-16 là thứ Năm → hết tuần = Chủ Nhật 2026-07-19 (không phải +7 ngày).
    today = date(2026, 7, 16)
    assert today.weekday() == 3  # Thursday
    w = resolve_plan_window(horizon="rest_of_week", today=today)
    assert w["from_date"] == "2026-07-16"
    assert w["to_date"] == "2026-07-19"

    # Hôm nay là Chủ Nhật → window chỉ còn 1 ngày.
    sunday = date(2026, 7, 19)
    w2 = resolve_plan_window(horizon="rest_of_week", today=sunday)
    assert w2["from_date"] == w2["to_date"] == "2026-07-19"


def test_suggested_count_honors_sessions_per_day():
    from app.tools.local import _suggested_session_count

    window = {"from_date": "2026-07-16", "to_date": "2026-07-19", "suggested_session_count": 3}
    # 2 buổi/ngày × 4 ngày = 8 (default 4 từng gây thiếu buổi).
    assert _suggested_session_count(window, sessions_per_day=2) == 8
    # 1 buổi/ngày → giữ suggested của window.
    assert _suggested_session_count(window, sessions_per_day=1) == 3
    # Cap trần 16 buổi.
    big = {"from_date": "2026-07-01", "to_date": "2026-07-21"}
    assert _suggested_session_count(big, sessions_per_day=3) == 16


# ---------------------------------------------------------------------------
# Đổi giờ buổi tập: chỉ CÙNG NGÀY + giờ mới TRƯỚC 22:00
# ---------------------------------------------------------------------------


def test_time_change_allows_same_day_before_22h():
    from app.tools.local import validate_time_change

    assert validate_time_change(
        current_date="2026-07-16", new_date="2026-07-16", new_time="18:00",
    ) is None
    # new_date rỗng = giữ nguyên ngày → hợp lệ
    assert validate_time_change(
        current_date="2026-07-16", new_date="", new_time="06:30",
    ) is None
    assert validate_time_change(
        current_date="2026-07-16", new_date="2026-07-16", new_time="21:59",
    ) is None


def test_time_change_rejects_22h_and_later():
    from app.tools.local import validate_time_change

    for t in ("22:00", "22:30", "23:00"):
        err = validate_time_change(
            current_date="2026-07-16", new_date="2026-07-16", new_time=t,
        )
        assert err is not None, t
        assert "22:00" in err


def test_time_change_rejects_cross_day():
    from app.tools.local import validate_time_change

    err = validate_time_change(
        current_date="2026-07-16", new_date="2026-07-17", new_time="06:30",
    )
    assert err is not None
    assert "cùng ngày" in err


def test_time_change_rejects_bad_format():
    from app.tools.local import validate_time_change

    for t in ("", "khuya", "25:00", "18:75", "6h30"):
        assert validate_time_change(
            current_date="2026-07-16", new_date="", new_time=t,
        ) is not None, t


@pytest.mark.asyncio
async def test_reschedule_tool_refuses_late_time(monkeypatch):
    """Staging: LLM đòi đổi sang 23:00 → tool trả error, KHÔNG stage pending."""
    from unittest.mock import AsyncMock

    from app.tools import dotnet as dotnet_mod
    from app.tools.catalog import build_impls
    from app.tools.context import ToolRunContext

    monkeypatch.setattr(
        dotnet_mod, "get_roadmap_session",
        AsyncMock(return_value={"scheduledDate": "2026-07-16T06:30:00+07:00"}),
    )
    ctx = ToolRunContext(user_id="u1", state={})
    impls = build_impls(ctx, ["reschedule_session"])
    out = await impls["reschedule_session"](
        session_id="853c1b55-add8-4fa6-beb9-2495cd57f2bc", new_time="23:00",
    )
    assert "error" in out
    assert "22:00" in out["error"]
    assert not ctx.pending_actions


@pytest.mark.asyncio
async def test_reschedule_tool_stages_same_day_change(monkeypatch):
    """Staging hợp lệ: đổi 06:30 → 18:00 cùng ngày, new_date tự chốt theo session."""
    from unittest.mock import AsyncMock

    from app.tools import dotnet as dotnet_mod
    from app.tools.catalog import build_impls
    from app.tools.context import ToolRunContext

    monkeypatch.setattr(
        dotnet_mod, "get_roadmap_session",
        AsyncMock(return_value={"scheduledDate": "2026-07-16T06:30:00+07:00"}),
    )
    ctx = ToolRunContext(user_id="u1", state={})
    impls = build_impls(ctx, ["reschedule_session"])
    out = await impls["reschedule_session"](
        session_id="853c1b55-add8-4fa6-beb9-2495cd57f2bc", new_time="18:00",
    )
    assert "error" not in out
    assert len(ctx.pending_actions) == 1
    pa = ctx.pending_actions[0]
    assert pa["type"] == "reschedule_session"
    assert pa["new_date"] == "2026-07-16"
    assert pa["new_time"] == "18:00"


# ---------------------------------------------------------------------------
# H. propose_order: id phải là GUID thật
# ---------------------------------------------------------------------------


def test_is_guid_rejects_fabricated_objectid():
    from app.graph.agents.commerce import _is_guid

    assert _is_guid("5f8e6f5c-4b1e-1e00-1c2c-4c7f00000000") is True
    # ObjectId kiểu Mongo mà LLM từng bịa ra trong log thực tế:
    assert _is_guid("5f8e6f5c4b1e1e001c2c4c7f") is False
    assert _is_guid("") is False
    assert _is_guid(None) is False
    assert _is_guid("not-a-guid") is False
