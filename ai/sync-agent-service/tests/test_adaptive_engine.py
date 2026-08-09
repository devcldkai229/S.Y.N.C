"""Unit tests — Adaptive Coaching Engine (tất định, theo design doc)."""
from __future__ import annotations

from datetime import date, timedelta

import pytest

from app.engine.adaptive import (
    EngineInput,
    apply_safety_rails,
    build_adjustment_plan,
    classify_change,
    compute_targets,
    confidence_weight,
    count_consecutive_off_target_weeks,
    ema_series,
    estimate_tdee_actual,
    eta_weeks,
    rate_correction_kcal,
    training_adjustment,
)


def _daily_weighins(start: date, days: int, w0: float, per_day: float) -> list[tuple[date, float]]:
    return [(start + timedelta(days=i), w0 + per_day * i) for i in range(days)]


# ── §3.1 EMA + outlier ───────────────────────────────────────────────────────

def test_ema_smooths_and_rejects_outliers():
    d0 = date(2026, 7, 1)
    pts = _daily_weighins(d0, 7, 90.0, -0.1)
    pts.insert(3, (d0 + timedelta(days=3), 96.5))  # nhiễu +6.5kg → phải bị loại
    out = ema_series(pts)
    assert all(abs(w - 90.0) < 2.0 for _, w in out)
    # outlier bị loại — số điểm hợp lệ = 7 (không tính điểm nhiễu)
    assert len(out) == 7


# ── §3.2 TDEE thực ───────────────────────────────────────────────────────────

def test_tdee_actual_energy_balance():
    # Ăn 1800, giảm 0.2kg trong 14 ngày → TDEE ≈ 1800 + 0.2*7700/14 = 1910
    assert round(estimate_tdee_actual(1800, 0.2, 14)) == 1910
    # Tăng 0.2kg (delta âm) → TDEE thấp hơn intake
    assert round(estimate_tdee_actual(1800, -0.2, 14)) == 1690


# ── §6 Confidence gate ───────────────────────────────────────────────────────

def test_confidence_zero_when_insufficient():
    assert confidence_weight(logged_days=5, weighin_count=5, weighin_span_days=14) == 0.0
    assert confidence_weight(logged_days=12, weighin_count=1, weighin_span_days=14) == 0.0
    assert confidence_weight(logged_days=12, weighin_count=3, weighin_span_days=3) == 0.0
    w = confidence_weight(logged_days=12, weighin_count=5, weighin_span_days=14)
    assert 0.4 <= w <= 1.0


# ── §3.4 Targets theo kg ─────────────────────────────────────────────────────

def test_targets_scale_with_weight():
    t90 = compute_targets(kind="deficit", tdee_used=2500, weight_kg=90)
    t80 = compute_targets(kind="deficit", tdee_used=2500, weight_kg=80)
    assert t90["protein_g"] > t80["protein_g"]  # protein co giãn theo kg
    assert t90["calories"] == t80["calories"] == round(2500 * 0.85)


# ── §3.5 Rate correction ─────────────────────────────────────────────────────

def test_rate_correction_steps_are_bounded():
    d, code = rate_correction_kcal(kind="deficit", rate_actual_pct_bw=0.001, target_calories=2000)
    assert code == "rate_too_slow" and d == -200  # giảm chậm → hạ ≤200
    d2, code2 = rate_correction_kcal(kind="deficit", rate_actual_pct_bw=0.015, target_calories=2000)
    assert code2 == "rate_too_fast" and d2 == 200  # giảm quá nhanh → NÂNG calo
    d3, code3 = rate_correction_kcal(kind="deficit", rate_actual_pct_bw=0.007, target_calories=2000)
    assert code3 == "on_track" and d3 == 0


def test_rate_correction_waits_for_two_weeks():
    d, code = rate_correction_kcal(
        kind="deficit", rate_actual_pct_bw=0.001, target_calories=2000,
        consecutive_off_target_weeks=1,
    )
    assert code == "awaiting_2_weeks" and d == 0


def test_count_consecutive_off_target_weeks_from_weighins():
    # Hai tuần ISO liên tiếp giảm quá chậm (~0.1%BW/tuần < 0.5%) → 2 tuần off
    d0 = date(2026, 6, 1)  # Mon
    pts: list[tuple[date, float]] = []
    # Week 1: Mon–Sun, tiny loss
    for i in range(7):
        pts.append((d0 + timedelta(days=i), 90.0 - 0.01 * i))
    # Week 2: again tiny loss
    for i in range(7):
        pts.append((d0 + timedelta(days=7 + i), 89.94 - 0.01 * i))
    assert count_consecutive_off_target_weeks(pts, "deficit") >= 2


def test_pipeline_skips_rate_correction_until_two_off_weeks():
    plan = build_adjustment_plan(_base_input(consecutive_off_target_weeks=1))
    assert plan["data_sufficient"] is True
    assert plan["rate"]["consecutive_off_target_weeks"] == 1
    assert any("chờ đủ 2 tuần" in r for r in plan["reasons"])
    # Không chỉnh calo vì rate gate
    assert not any("rate_too_slow" in r for r in plan["reasons"])


def test_pipeline_weekly_cap_blocks_auto_apply():
    plan = build_adjustment_plan(_base_input(
        consecutive_off_target_weeks=2,
        days_since_last_adjustment=3,
        old_calories=2300,
    ))
    assert plan["weekly_cap_hit"] is True
    assert plan["auto_apply"] is False
    assert plan["change_class"] == "small"
    assert any("1 lần/tuần" in r for r in plan["reasons"])


def test_pipeline_no_weekly_cap_when_adjustment_old():
    plan = build_adjustment_plan(_base_input(
        consecutive_off_target_weeks=2,
        days_since_last_adjustment=10,
        old_calories=2300,
    ))
    assert plan["weekly_cap_hit"] is False


# ── §5 Rào an toàn ───────────────────────────────────────────────────────────

def test_safety_floor_and_protein_kept():
    cal, protein, flags = apply_safety_rails(
        calories=1000, bmr=1400, tdee_used=2000, sex="female",
        old_protein_g=150, protein_g=120, kind="deficit",
    )
    assert cal >= 1400 * 1.1 - 1  # sàn max(BMR*1.1, 1200)
    assert protein == 150          # protein không giảm khi cắt
    assert "calorie_floor" in flags and "protein_kept" in flags


# ── §3.6 Training ────────────────────────────────────────────────────────────

def test_training_decision_matrix():
    assert training_adjustment(completion_rate=0.9, volume_trend_pct=2, recovery_index=7)["action"] == "progress"
    assert training_adjustment(completion_rate=0.7, volume_trend_pct=0, recovery_index=6)["action"] == "hold"
    assert training_adjustment(completion_rate=0.5, volume_trend_pct=0, recovery_index=6)["action"] == "deload"
    assert training_adjustment(completion_rate=0.9, volume_trend_pct=2, recovery_index=2)["action"] == "deload"
    assert training_adjustment(completion_rate=0.9, volume_trend_pct=2, recovery_index=7,
                               new_injury=True)["action"] == "substitute"


# ── §7 Phân mức ──────────────────────────────────────────────────────────────

def test_change_classification():
    assert classify_change(old_calories=2000, new_calories=2060, training_action="hold") == "small"
    assert classify_change(old_calories=2000, new_calories=2160, training_action="hold") == "medium"
    assert classify_change(old_calories=2000, new_calories=2400, training_action="hold") == "large"
    assert classify_change(old_calories=2000, new_calories=2000, training_action="deload") == "large"


def test_eta():
    assert eta_weeks(90, 80, 0.5) == 20.0
    assert eta_weeks(90, 80, 0.0) is None


# ── End-to-end pipeline ──────────────────────────────────────────────────────

def _base_input(**over) -> EngineInput:
    d0 = date(2026, 7, 1)
    defaults = dict(
        sex="male", bmr_override=1800, height_cm=173, activity_level="ModeratelyActive",
        fitness_goal="LoseFat", experience_level="Beginner", target_weight_kg=80,
        weighins=_daily_weighins(d0, 15, 92.0, -0.02),  # giảm chậm ~0.14kg/tuần
        avg_intake_kcal=1800, logged_days=12,
        old_calories=2300, old_protein_g=180, old_carb_g=200, old_fat_g=70,
        completion_rate=0.8, consistency_score=80, progression_score=70,
        recovery_capacity_score=70, recovery_index=7.0,
        consecutive_off_target_weeks=2,
    )
    defaults.update(over)
    return EngineInput(**defaults)


def test_pipeline_sufficient_data_adjusts_with_reasons():
    plan = build_adjustment_plan(_base_input())
    assert plan["data_sufficient"] is True
    assert plan["targets_new"]["calories"] > 0
    assert plan["targets_new"]["protein_g"] >= 180  # protein không giảm khi cắt
    assert plan["change_class"] in ("small", "medium", "large")
    assert plan["reasons"] and plan["factors"]
    assert plan["confidence"] in ("cao", "trung bình", "thấp")
    # Giảm quá chậm (0.15%BW/tuần < 0.5%) → có lý do rate + calo bị kéo xuống
    assert any("rate_too_slow" in r or "Tốc độ thực" in r for r in plan["reasons"])


def test_pipeline_insufficient_data_no_strong_adjust():
    plan = build_adjustment_plan(_base_input(logged_days=3))
    assert plan["data_sufficient"] is False
    assert plan["confidence"] == "thấp"
    assert plan["auto_apply"] is False          # thiếu dữ liệu → không auto
    assert plan["change_class"] != "large"      # không đề xuất mạnh
    assert any("Chưa đủ dữ liệu" in r for r in plan["reasons"])


# ── Premium gate (server-side) ───────────────────────────────────────────────

@pytest.mark.asyncio
async def test_log_weight_gated_for_free_users():
    from app.tools.adaptive_tools import log_weight
    from app.tools.context import ToolRunContext

    ctx = ToolRunContext(user_id="u1", state={"subscription_tier": "Free", "user_snapshot": {}})
    out = await log_weight(ctx, 92.0)
    assert out.get("status") == "premium_required"
    assert ctx.pending_actions and ctx.pending_actions[0]["type"] == "upgrade_premium"
    assert any(p.get("type") == "premium_upsell" for p in ctx.display_payload)


@pytest.mark.asyncio
async def test_log_weight_rejects_invalid_weight(monkeypatch):
    from app.tools import adaptive_tools
    from app.tools.context import ToolRunContext

    ctx = ToolRunContext(user_id="u1", state={"subscription_tier": "Premium", "user_snapshot": {}})
    out = await adaptive_tools.log_weight(ctx, 5.0)
    assert "error" in out


def test_has_injury_from_snapshot():
    from app.tools.adaptive_tools import _has_injury

    assert _has_injury({"injuries": ["shoulder"]}) is True
    assert _has_injury({"injuries": ["none"]}) is False
    assert _has_injury({"injuries": []}) is False
    assert _has_injury({}) is False
