"""Tools Adaptive Coaching Engine — log_weight + get_adaptive_plan.

CHỈ PREMIUM/ULTRA (gate server-side, tái dùng _premium_block như insight).
Engine tất định (app/engine/adaptive.py) tính; LLM chỉ diễn giải AdjustmentPlan.
Tối ưu chi phí: vài HTTP call nội bộ, KHÔNG LLM call trong pipeline tính toán.
"""
from __future__ import annotations

import uuid
from datetime import date, datetime, timedelta, timezone
from typing import Any

from app.engine.adaptive import WINDOW_DAYS, EngineInput, build_adjustment_plan
from app.tools import dotnet
from app.tools.context import ToolRunContext
from app.tools.insight_stats import _premium_block, _tier, _unwrap_items
from app.graph.subscription_gating import insight_premium_allowed
from app.tools.time_utils import local_today

ADAPTIVE_FEATURE = "Adaptive Coaching — tự điều chỉnh calo/macro & lộ trình theo cân nặng thực tế"


def _snap(ctx: ToolRunContext) -> dict[str, Any]:
    return ctx.state.get("user_snapshot") or {}


def _num(v: Any, default: float = 0.0) -> float:
    try:
        return float(v)
    except (TypeError, ValueError):
        return default


def _parse_dt(raw: Any) -> datetime | None:
    if raw is None:
        return None
    if isinstance(raw, datetime):
        return raw if raw.tzinfo else raw.replace(tzinfo=timezone.utc)
    s = str(raw).strip()
    if not s:
        return None
    try:
        if s.endswith("Z"):
            s = s[:-1] + "+00:00"
        dt = datetime.fromisoformat(s)
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except ValueError:
        try:
            return datetime.fromisoformat(s[:10]).replace(tzinfo=timezone.utc)
        except ValueError:
            return None


_NO_INJURY = frozenset({"none", "không", "khong", "n/a", "no", "không có", "khong co"})


def _has_injury(snap: dict[str, Any]) -> bool:
    injuries = snap.get("injuries") or snap.get("Injuries") or []
    if not isinstance(injuries, list):
        return bool(injuries) and str(injuries).strip().lower() not in _NO_INJURY
    for item in injuries:
        if isinstance(item, str):
            name = item.strip().lower()
            if name and name not in _NO_INJURY:
                return True
        elif isinstance(item, dict):
            name = str(item.get("name") or item.get("bodyPart") or item.get("note") or "").strip().lower()
            if name and name not in _NO_INJURY:
                return True
    return False


def _days_since_last_adjustment(snap: dict[str, Any]) -> int | None:
    raw = snap.get("targetsAdjustedAtUtc") or snap.get("TargetsAdjustedAtUtc")
    dt = _parse_dt(raw)
    if dt is None:
        return None
    now = datetime.now(timezone.utc)
    return max(0, int((now - dt.astimezone(timezone.utc)).total_seconds() // 86400))


async def _fetch_weighins(user_id: str, today: date, days: int = 21) -> list[tuple[date, float]]:
    # IAM Npgsql requires timestamptz-safe bounds. date-only ("2026-06-28") binds as
    # DateTimeKind.Unspecified and throws → GlobalExceptionHandler 500.
    from_iso = f"{(today - timedelta(days=days)).isoformat()}T00:00:00Z"
    to_iso = f"{(today + timedelta(days=1)).isoformat()}T00:00:00Z"
    raw = await dotnet.get_weight_history(
        user_id,
        from_iso=from_iso,
        to_iso=to_iso,
    )
    out: list[tuple[date, float]] = []
    for item in _unwrap_items(raw):
        if not isinstance(item, dict):
            continue
        ts = str(item.get("recordedAtUtc") or item.get("RecordedAtUtc") or "")[:10]
        w = _num(item.get("weightKg", item.get("WeightKg")))
        try:
            d = date.fromisoformat(ts)
        except ValueError:
            continue
        if w > 0:
            out.append((d, w))
    return out


async def _fetch_nutrition_window(user_id: str, today: date) -> tuple[float | None, int]:
    """(avg intake kcal các ngày có log, số ngày có log) trong cửa sổ 14 ngày."""
    raw = await dotnet.get_nutrition_timeseries(
        user_id,
        from_date=(today - timedelta(days=WINDOW_DAYS - 1)).isoformat(),
        to_date=today.isoformat(),
        granularity="day",
    )
    intakes: list[float] = []
    for b in _unwrap_items(raw):
        if not isinstance(b, dict):
            continue
        cin = _num(b.get("consumedCalories", b.get("ConsumedCalories")))
        meals = int(_num(b.get("mealsLoggedCount", b.get("MealsLoggedCount"))))
        if meals > 0 or cin > 0:
            intakes.append(cin)
    if not intakes:
        return (None, 0)
    return (sum(intakes) / len(intakes), len(intakes))


async def _fetch_training_signals(
    user_id: str, today: date,
) -> tuple[float, float, float, float]:
    """(completion_rate 0..1, volume_trend_pct, volume_load_weekly, progression_score 0..100)."""
    raw = await dotnet.get_workout_timeseries(
        user_id,
        from_date=(today - timedelta(days=27)).isoformat(),
        to_date=today.isoformat(),
        granularity="week",
    )
    buckets = [
        b for b in _unwrap_items(raw)
        if isinstance(b, dict)
    ]
    if not buckets:
        return (0.0, 0.0, 0.0, 0.0)

    def _vol(b: dict[str, Any]) -> float:
        return _num(b.get("volume", b.get("Volume")))

    def _comp(b: dict[str, Any]) -> float:
        # CompletionRate in timeseries is 0..100
        c = _num(b.get("completionRate", b.get("CompletionRate")))
        return c / 100.0 if c > 1.0 else c

    volumes = [_vol(b) for b in buckets]
    comps = [_comp(b) for b in buckets]
    volume_weekly = volumes[-1] if volumes else 0.0
    completion = comps[-1] if comps else 0.0
    if len(comps) >= 2:
        completion = sum(comps[-2:]) / 2.0

    volume_trend_pct = 0.0
    if len(volumes) >= 2 and volumes[-2] > 0:
        volume_trend_pct = ((volumes[-1] - volumes[-2]) / volumes[-2]) * 100.0
    elif len(volumes) >= 2 and volumes[-1] > 0 and volumes[-2] == 0:
        volume_trend_pct = 100.0

    # Progression: rising volume → up to 100; flat/down → lower
    if volume_trend_pct >= 5:
        progression = min(100.0, 60.0 + volume_trend_pct)
    elif volume_trend_pct >= 0:
        progression = 55.0 + volume_trend_pct * 2
    else:
        progression = max(20.0, 50.0 + volume_trend_pct)

    return (completion, volume_trend_pct, volume_weekly, progression)


def _engine_input_from(
    ctx: ToolRunContext,
    weighins: list[tuple[date, float]],
    avg_intake: float | None,
    logged_days: int,
    *,
    completion_rate: float | None = None,
    volume_trend_pct: float = 0.0,
    volume_load_weekly: float = 0.0,
    progression_score: float | None = None,
) -> EngineInput:
    snap = _snap(ctx)
    adherence = _num(snap.get("adherenceScore"), 60.0)          # 0..100
    recovery = _num(snap.get("recoveryScore"), 60.0)            # 0..100
    comp = completion_rate if completion_rate is not None else adherence / 100.0
    prog = progression_score if progression_score is not None else adherence
    return EngineInput(
        sex=str(snap.get("gender") or "male"),
        bmr_override=_num(snap.get("bmr", snap.get("Bmr"))) or None,
        height_cm=_num(snap.get("heightCm"), 170.0),
        activity_level=str(snap.get("activityLevel") or "ModeratelyActive"),
        fitness_goal=str(snap.get("fitnessGoal") or "Maintain"),
        experience_level=str(snap.get("experienceLevel") or "Beginner"),
        target_weight_kg=_num(snap.get("targetWeightKg")) or None,
        weighins=weighins,
        avg_intake_kcal=avg_intake,
        logged_days=logged_days,
        old_calories=_num(snap.get("dailyCalorieTarget")) or _num(snap.get("baseTDEE")) or None,
        old_protein_g=_num(snap.get("dailyProteinTargetGram")) or None,
        old_carb_g=_num(snap.get("dailyCarbTargetGram")) or None,
        old_fat_g=_num(snap.get("dailyFatTargetGram")) or None,
        completion_rate=comp,
        consistency_score=adherence,
        progression_score=prog,
        recovery_capacity_score=recovery,
        recovery_index=recovery / 10.0,
        new_injury=_has_injury(snap),
        days_since_last_adjustment=_days_since_last_adjustment(snap),
        volume_load_weekly=volume_load_weekly,
        volume_trend_pct=volume_trend_pct,
    )


def _plan_card(plan: dict[str, Any]) -> dict[str, Any]:
    """display_payload card so sánh cũ→mới cho client render."""
    return {
        "type": "adjustment_plan",
        "goalKind": plan["goal_kind"],
        "weightKg": plan["weight"]["ema_kg"],
        "old": plan["targets_old"],
        "new": plan["targets_new"],
        "tdee": plan["tdee"],
        "etaWeeks": plan["eta_weeks"],
        "level": plan["level"],
        "training": plan["training"],
        "confidence": plan["confidence"],
        "changeClass": plan["change_class"],
        "autoApplied": plan["auto_apply"],
        "reasons": plan["reasons"][:4],
        "factors": plan["factors"],
    }


def _apply_payload(plan: dict[str, Any], *, trigger: str, mode: str, roadmap_changed: bool = False) -> dict[str, Any]:
    t = plan["targets_new"]
    return {
        "newCalories": int(t["calories"]),
        "newProteinGram": int(t["protein_g"]),
        "newCarbGram": int(t["carb_g"]),
        "newFatGram": int(t["fat_g"]),
        "estimatedTdee": int(plan["tdee"]["actual"]),
        "formulaTdee": int(plan["tdee"]["formula"]),
        "trigger": trigger,
        "confidenceLevel": plan["confidence"],
        "reasonCode": plan["training"]["action"] + ("+insufficient" if not plan["data_sufficient"] else ""),
        "reasonText": " | ".join(plan["reasons"])[:1900],
        "appliedMode": mode,
        "roadmapChanged": roadmap_changed,
    }


def _training_body(plan: dict[str, Any]) -> dict[str, Any]:
    tr = plan.get("training") or {}
    action = str(tr.get("action") or "hold")
    volume_delta = _num(tr.get("volume_change_pct", tr.get("load_change_pct")))
    return {
        "decision": action,
        "volumeDeltaPct": volume_delta,
        "etaWeeks": plan.get("eta_weeks"),
        "phase": plan.get("goal_kind"),
    }


def _level_snapshot_body(plan: dict[str, Any]) -> dict[str, Any] | None:
    level = plan.get("level") or {}
    if not level or level.get("score") is None:
        return None
    return {
        "levelScore": level["score"],
        "tier": level.get("tier") or "Beginner",
        "consistencyScore": level.get("consistency", 0),
        "progressionScore": level.get("progression", 0),
        "recoveryCapacityScore": level.get("recovery_capacity", 0),
        "volumeLoadWeekly": level.get("volume_load_weekly", 0),
    }


async def _apply_training_and_snapshot(
    user_id: str, plan: dict[str, Any],
) -> tuple[bool, dict[str, Any] | None]:
    """Apply Roadmap volume adjustment when needed; always try persist level snapshot."""
    roadmap_changed = False
    training_result: dict[str, Any] | None = None
    action = str((plan.get("training") or {}).get("action") or "hold")
    if action in ("deload", "progress"):
        try:
            training_result = await dotnet.apply_training_adjustment(user_id, _training_body(plan))
            status = str(
                (training_result or {}).get("status")
                or ((training_result or {}).get("data") or {}).get("status")
                or ""
            ).lower()
            sessions = _num(
                (training_result or {}).get("sessionsAdjusted")
                or ((training_result or {}).get("data") or {}).get("sessionsAdjusted")
            )
            roadmap_changed = status == "applied" or sessions > 0
        except Exception as exc:  # noqa: BLE001 — soft-fail training path
            training_result = {"error": str(exc)}

    snap_body = _level_snapshot_body(plan)
    if snap_body:
        try:
            await dotnet.create_level_snapshot(user_id, snap_body)
        except Exception:
            pass
    return roadmap_changed, training_result


async def _sync_roadmap_body_metrics(
    user_id: str,
    *,
    weight_kg: float | None = None,
    body_fat: float | None = None,
    plan: dict[str, Any] | None = None,
) -> dict[str, Any] | None:
    """Mirror cân/mỡ (+ target weight từ snapshot plan nếu có) lên PersonalizedRoadmap."""
    target_w: float | None = None
    phase: str | None = None
    if plan:
        # Engine không rewrite phase; chỉ sync target weight từ snapshot nếu caller truyền.
        tw = plan.get("target_weight_kg")
        if tw is not None:
            target_w = _num(tw) or None
        phase_raw = plan.get("current_phase") or plan.get("currentPhase")
        if isinstance(phase_raw, str) and phase_raw.strip():
            phase = phase_raw.strip()
    if weight_kg is None and body_fat is None and target_w is None and not phase:
        return None
    try:
        return await dotnet.sync_roadmap_body_metrics(
            user_id,
            current_weight_kg=weight_kg,
            target_weight_kg=target_w,
            initial_fat_percentage=body_fat,
            current_phase=phase,
        )
    except Exception as exc:  # noqa: BLE001 — soft-fail; IAM weigh-in path cũng sync
        return {"error": str(exc)}


async def _refresh_snapshot(ctx: ToolRunContext | None, user_id: str) -> None:
    """Invalidate Redis + refresh IAM snapshot so CYN không giữ cân/kcal cũ."""
    from app.graph.context import refresh_user_snapshot

    state: dict[str, Any] = ctx.state if ctx is not None else {"user_id": user_id}
    if "user_id" not in state:
        state = {**state, "user_id": user_id}
    try:
        await refresh_user_snapshot(state)
    except Exception:
        pass


async def _run_pipeline(ctx: ToolRunContext, *, trigger: str) -> dict[str, Any]:
    today = local_today(ctx.state)
    weighins = await _fetch_weighins(ctx.user_id, today)
    avg_intake, logged_days = await _fetch_nutrition_window(ctx.user_id, today)
    completion, vol_trend, vol_weekly, progression = await _fetch_training_signals(ctx.user_id, today)
    snap = _snap(ctx)
    # Prefer real workout completion; fall back to adherence when no logs
    if completion <= 0 and _num(snap.get("adherenceScore")) > 0:
        completion = _num(snap.get("adherenceScore")) / 100.0
    plan = build_adjustment_plan(_engine_input_from(
        ctx, weighins, avg_intake, logged_days,
        completion_rate=completion,
        volume_trend_pct=vol_trend,
        volume_load_weekly=vol_weekly,
        progression_score=progression if vol_weekly > 0 else None,
    ))

    if plan["auto_apply"] and plan["data_sufficient"]:
        roadmap_changed, training_result = await _apply_training_and_snapshot(ctx.user_id, plan)
        applied = await dotnet.apply_adaptive_targets(
            ctx.user_id,
            _apply_payload(plan, trigger=trigger, mode="Auto", roadmap_changed=roadmap_changed),
        )
        # Sync cân EMA lên roadmap + refresh snapshot (kcal đã apply trên IAM).
        w_ema = _num((plan.get("weight") or {}).get("ema_kg"))
        tw = _num(snap.get("targetWeightKg") or snap.get("TargetWeightKg")) or None
        plan_for_sync = {**plan, "target_weight_kg": tw} if tw else plan
        await _sync_roadmap_body_metrics(
            ctx.user_id,
            weight_kg=w_ema if w_ema > 0 else None,
            plan=plan_for_sync,
        )
        await _refresh_snapshot(ctx, ctx.user_id)
        plan["applied"] = applied
        plan["training_applied"] = training_result
        plan["roadmap_changed"] = roadmap_changed
        ctx.display_payload.append(_plan_card(plan))
        return {
            "status": "auto_applied",
            "plan": plan,
            "message": (
                f"Đã tinh chỉnh nhẹ mục tiêu: {plan['targets_new']['calories']} kcal "
                f"· P{plan['targets_new']['protein_g']}/C{plan['targets_new']['carb_g']}"
                f"/F{plan['targets_new']['fat_g']}g (độ tin cậy: {plan['confidence']})."
            ),
        }

    # Mức VỪA/LỚN → pending_action chờ xác nhận (human-in-the-loop §7)
    action_id = str(uuid.uuid4())
    ctx.display_payload.append(_plan_card(plan))
    ctx.pending_actions.append({
        "action_id": action_id,
        "type": "apply_adjustment",
        "status": "awaiting_confirmation",
        "apply_payload": _apply_payload(plan, trigger=trigger, mode="Confirmed"),
        "plan_snapshot": {
            "training": plan.get("training"),
            "level": plan.get("level"),
            "eta_weeks": plan.get("eta_weeks"),
            "goal_kind": plan.get("goal_kind"),
            "weight": plan.get("weight"),
            "target_weight_kg": _num(snap.get("targetWeightKg") or snap.get("TargetWeightKg")) or None,
        },
        "summary": (
            f"Điều chỉnh mục tiêu → {plan['targets_new']['calories']} kcal · "
            f"P{plan['targets_new']['protein_g']}g (độ tin cậy: {plan['confidence']})"
        ),
    })
    return {
        "status": "pending_confirmation",
        "action_id": action_id,
        "plan": plan,
        "message": "Đề xuất điều chỉnh đã sẵn — chờ user bấm xác nhận trên card.",
    }


async def log_weight(
    ctx: ToolRunContext,
    weight_kg: float,
    body_fat_percentage: float | None = None,
    note: str = "",
) -> dict[str, Any]:
    """User báo cân nặng mới → ghi BiometricHistory → chạy full engine (§9)."""
    ctx.tools_called.append("log_weight")
    if not insight_premium_allowed(_tier(ctx)):
        return _premium_block(ctx, feature=ADAPTIVE_FEATURE)

    w = _num(weight_kg)
    if w < 20 or w > 400:
        return {"error": f"Cân nặng {weight_kg} không hợp lệ (20-400kg). Kiểm tra lại giúp mình."}

    recorded = await dotnet.log_weigh_in(
        ctx.user_id, weight_kg=w,
        body_fat_percentage=body_fat_percentage, note=note or None,
    )
    # IAM cũng sync roadmap; call lại để chắc chắn + hỗ trợ fat % từ chat.
    await _sync_roadmap_body_metrics(
        ctx.user_id,
        weight_kg=w,
        body_fat=_num(body_fat_percentage) if body_fat_percentage is not None else None,
    )
    result = await _run_pipeline(ctx, trigger="WeighIn")
    # Pipeline may refresh on auto_apply; always refresh after weigh-in for weight fields.
    if result.get("status") != "auto_applied":
        await _refresh_snapshot(ctx, ctx.user_id)
    result["weigh_in"] = recorded
    result["disclaimer"] = "Ước lượng từ dữ liệu thật; không phải tư vấn y khoa."
    return result


async def get_adaptive_plan(ctx: ToolRunContext, trigger: str = "Weekly") -> dict[str, Any]:
    """Chạy engine không cần weigh-in mới (WeeklyRecalibration / user hỏi 'xem điều chỉnh')."""
    ctx.tools_called.append("get_adaptive_plan")
    if not insight_premium_allowed(_tier(ctx)):
        return _premium_block(ctx, feature=ADAPTIVE_FEATURE)

    trig = trigger if trigger in ("Weekly", "Plateau", "ProfileChange", "Recovery", "WeighIn") else "Weekly"
    result = await _run_pipeline(ctx, trigger=trig)
    result["disclaimer"] = "Ước lượng từ dữ liệu thật; không phải tư vấn y khoa."
    return result


async def execute_apply_adjustment(user_id: str, action: dict[str, Any]) -> dict[str, Any]:
    """Confirm executor (main.py) — áp targets sau khi user bấm xác nhận."""
    payload = action.get("apply_payload")
    if not isinstance(payload, dict):
        return {"status": "error", "message": "Thiếu apply_payload trong pending action."}

    plan_snap = action.get("plan_snapshot") or {}
    weight_block = plan_snap.get("weight") if isinstance(plan_snap.get("weight"), dict) else {}
    pseudo_plan = {
        "training": plan_snap.get("training") or {"action": "hold"},
        "level": plan_snap.get("level") or {},
        "eta_weeks": plan_snap.get("eta_weeks"),
        "goal_kind": plan_snap.get("goal_kind"),
        "weight": weight_block,
        "target_weight_kg": plan_snap.get("target_weight_kg"),
        "data_sufficient": True,
        "reasons": [],
        "tdee": {"actual": payload.get("estimatedTdee", 0), "formula": payload.get("formulaTdee", 0)},
        "targets_new": {
            "calories": payload.get("newCalories"),
            "protein_g": payload.get("newProteinGram"),
            "carb_g": payload.get("newCarbGram"),
            "fat_g": payload.get("newFatGram"),
        },
    }
    roadmap_changed, training_result = await _apply_training_and_snapshot(user_id, pseudo_plan)
    payload = {**payload, "roadmapChanged": roadmap_changed}
    applied = await dotnet.apply_adaptive_targets(user_id, payload)
    w_ema = _num(weight_block.get("ema_kg"))
    await _sync_roadmap_body_metrics(
        user_id,
        weight_kg=w_ema if w_ema > 0 else None,
        plan=pseudo_plan,
    )
    await _refresh_snapshot(None, user_id)
    return {
        "applied": applied,
        "training_applied": training_result,
        "roadmap_changed": roadmap_changed,
        "message": (
            f"Đã cập nhật mục tiêu: {payload['newCalories']} kcal · "
            f"P{payload['newProteinGram']}/C{payload['newCarbGram']}/F{payload['newFatGram']}g. "
            "Nutrition targets có hiệu lực ngay."
        ),
    }
