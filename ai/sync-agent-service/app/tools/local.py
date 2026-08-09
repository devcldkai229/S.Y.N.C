"""Local tools — pgvector memory, handoff, insight heuristics, vision stub."""
from __future__ import annotations

import asyncio
from datetime import date, datetime, timedelta, timezone
from typing import Any, Mapping

from app.config import get_settings
from app.memory.checkpointer import SemanticMemory
from app.tools import dotnet
from app.tools.context import ToolRunContext
from app.tools.time_utils import DEFAULT_TZ, local_today, resolve_tz_name
from app.text_norm import strip_accents

_memory: SemanticMemory | None = None


def _mem() -> SemanticMemory:
    global _memory
    if _memory is None:
        _memory = SemanticMemory()
    return _memory


async def remember_user_fact(ctx: ToolRunContext, fact: str) -> dict[str, Any]:
    fact = (fact or "").strip()[:200]
    if not fact:
        return {"error": "fact is required"}
    await _mem().remember(ctx.user_id, fact)
    return {"ok": True, "stored": fact}


async def recall_user_memory(ctx: ToolRunContext, query: str, k: int = 5) -> dict[str, Any]:
    facts = await _mem().recall(ctx.user_id, query, k=k)
    return {"facts": facts}


async def handoff(ctx: ToolRunContext, target_agent: str, reason: str = "") -> dict[str, Any]:
    valid = {"coach", "nutrition", "workout", "commerce", "insight"}
    target = (target_agent or "").strip().lower()
    if target not in valid:
        return {"error": f"invalid target_agent: {target_agent}"}
    current = (ctx.state.get("target_agent") or ctx.state.get("intent") or "").strip().lower()
    if current and target == current:
        return {
            "error": "same_agent",
            "message": f"Đang ở {current} — không handoff sang cùng agent.",
        }
    # Reject vague / empty reason when switching domains (soft: still allow if reason given).
    ctx.next_agent = target
    ctx.handoff_reason = reason
    return {"handoff": target, "reason": reason}


async def escalate_to_human(
    ctx: ToolRunContext, reason: str, severity: str = "high",
) -> dict[str, Any]:
    payload = {
        "type": "AiIntervention",
        "channel": "InApp",
        "priority": "High",
        "title": "Hỗ trợ khẩn cấp",
        "body": reason or "Người dùng cần được kết nối với chuyên viên hỗ trợ.",
        "deepLink": "sync://support/crisis",
        "allowAiGenerated": False,
    }
    try:
        await dotnet.send_notification(ctx.user_id, payload)
    except Exception as exc:
        return {"error": str(exc), "escalated": True, "resources": _crisis_resources()}
    return {"escalated": True, "severity": severity, "resources": _crisis_resources()}


def _crisis_resources() -> list[dict[str, str]]:
    return [
        {"name": "Tổng đài 111 (VN)", "phone": "111"},
        {"name": "Bệnh viện tâm thần gần nhất", "deepLink": "sync://map/hospitals"},
    ]


async def log_mood_checkin(ctx: ToolRunContext, mood: str, note: str = "") -> dict[str, Any]:
    payload: dict[str, Any] = {"currentMood": mood}
    if note:
        payload["moodNote"] = note
    return await dotnet.patch_ai_context(ctx.user_id, payload)


def _extract_number(row: dict[str, Any], *keys: str) -> float | None:
    for key in keys:
        val = row.get(key)
        if val is not None:
            try:
                return float(val)
            except (TypeError, ValueError):
                continue
    return None


async def _fetch_nutrition_points(
    user_id: str, days: int, metric: str, *, today: date | None = None,
) -> list[dict[str, Any]]:
    today = today or local_today()

    async def _one(d: str) -> dict[str, Any]:
        try:
            row = await dotnet.get_daily_summary(user_id, date=d)
            val = _extract_number(row, metric, "totalCalories", "calories", "waterIntakeMl", "proteinGram")
            return {"date": d, "value": val}
        except Exception:
            return {"date": d, "value": None}

    dates = [(today - timedelta(days=i)).isoformat() for i in range(days)]
    return list(await asyncio.gather(*[_one(d) for d in dates]))


async def _fetch_workout_points(
    user_id: str, days: int, *, today: date | None = None, tz_name: str = DEFAULT_TZ,
) -> list[dict[str, Any]]:
    today = today or local_today()
    start = today - timedelta(days=days)
    try:
        data = await dotnet.get_workout_executions_range(
            user_id,
            from_iso=start.isoformat(),
            to_iso=today.isoformat(),
            time_zone_id=tz_name,
        )
        items = data.get("items", data if isinstance(data, list) else [])
        if not isinstance(items, list):
            items = []
        by_date: dict[str, int] = {}
        for item in items:
            if not isinstance(item, dict):
                continue
            started = item.get("startedAt") or item.get("StartedAt")
            if not started:
                continue
            day = str(started)[:10]
            by_date[day] = by_date.get(day, 0) + 1
        return [{"date": d, "value": by_date.get(d, 0)} for d in
                [(today - timedelta(days=i)).isoformat() for i in range(days)]]
    except Exception:
        return [{"date": (today - timedelta(days=i)).isoformat(), "value": None}
                for i in range(days)]


async def get_progress_trends(
    ctx: ToolRunContext, metric: str = "calories", days: int = 7,
) -> dict[str, Any]:
    days = max(1, min(days, 30))
    metric_key = (metric or "calories").lower()
    today = local_today(ctx)
    tz = resolve_tz_name(ctx)

    if metric_key in ("workouts", "workout", "sessions"):
        points = await _fetch_workout_points(ctx.user_id, days, today=today, tz_name=tz)
    elif metric_key == "adherence":
        nutrition_pts, workout_pts = await asyncio.gather(
            _fetch_nutrition_points(ctx.user_id, days, "totalCalories", today=today),
            _fetch_workout_points(ctx.user_id, days, today=today, tz_name=tz),
        )
        points = []
        for n, w in zip(nutrition_pts, workout_pts):
            n_val = n.get("value")
            w_val = w.get("value") or 0
            score = None
            if n_val is not None:
                score = min(1.0, (1.0 if n_val > 0 else 0.0) * 0.5 + (1.0 if w_val > 0 else 0.0) * 0.5)
            points.append({"date": n["date"], "value": score})
    else:
        nut_metric = {
            "calories": "totalCalories",
            "protein": "proteinGram",
            "water": "waterIntakeMl",
        }.get(metric_key, metric_key)
        points = await _fetch_nutrition_points(ctx.user_id, days, nut_metric, today=today)

    values = [p["value"] for p in points if p["value"] is not None]
    avg = sum(values) / len(values) if values else 0
    return {"metric": metric, "days": days, "points": points, "average": avg}


async def detect_burnout(ctx: ToolRunContext) -> dict[str, Any]:
    trends, recovery, workout_trends = await asyncio.gather(
        get_progress_trends(ctx, metric="adherence", days=10),
        dotnet.get_recovery_status(ctx.user_id),
        get_progress_trends(ctx, metric="workouts", days=10),
    )
    low_adherence = (trends.get("average") or 0) < 0.35
    no_workouts = (workout_trends.get("average") or 0) < 0.3
    fatigue = recovery.get("fatigueLevel") or recovery.get("fatigue")
    score = 0.35
    if low_adherence:
        score += 0.25
    if no_workouts:
        score += 0.2
    if fatigue and str(fatigue).lower() in ("high", "severe"):
        score = min(1.0, score + 0.25)
    return {
        "burnoutRiskScore": round(min(1.0, score), 3),
        "signals": {"low_adherence": low_adherence, "no_workouts": no_workouts, "fatigue": fatigue},
    }


async def detect_plateau(ctx: ToolRunContext, metric: str = "weight") -> dict[str, Any]:
    trends = await get_progress_trends(ctx, metric=metric, days=21)
    values = [p["value"] for p in trends.get("points", []) if p["value"] is not None]
    if len(values) < 5:
        return {"plateau": False, "reason": "insufficient_data"}
    spread = max(values) - min(values)
    denom = max(values) or 1.0
    return {"plateau": spread < 0.05 * denom, "metric": metric, "spread": spread}


async def generate_weekly_report(ctx: ToolRunContext) -> dict[str, Any]:
    nutrition, workouts, gamification, recovery, roadmap = await asyncio.gather(
        get_progress_trends(ctx, metric="totalCalories", days=7),
        get_progress_trends(ctx, metric="workouts", days=7),
        dotnet.get_gamification_status(ctx.user_id),
        dotnet.get_recovery_status(ctx.user_id),
        dotnet.get_active_roadmap(ctx.user_id),
    )
    report = {
        "nutritionTrend": nutrition,
        "workoutTrend": workouts,
        "workoutSnapshot": await dotnet.get_today_workout(
            ctx.user_id, time_zone_id=resolve_tz_name(ctx),
        ),
        "activeRoadmap": roadmap,
        "recovery": recovery,
        "gamification": gamification,
        "summary": "Báo cáo tuần — xem chi tiết trong display_payload.",
    }
    ctx.display_payload.append({"type": "weekly_report", "data": report})
    return report


async def compute_and_update_ai_scores(ctx: ToolRunContext) -> dict[str, Any]:
    adherence_trends, burnout, workout_trends = await asyncio.gather(
        get_progress_trends(ctx, metric="adherence", days=14),
        detect_burnout(ctx),
        get_progress_trends(ctx, metric="workouts", days=14),
    )
    adherence = float(adherence_trends.get("average") or 0.5)
    workout_rate = min(1.0, float(workout_trends.get("average") or 0) / 1.0)
    adherence = round((adherence * 0.6) + (workout_rate * 0.4), 3)
    burnout_score = float(burnout.get("burnoutRiskScore") or 0.3)
    recovery = max(0.0, min(1.0, 1.0 - burnout_score))
    patch = {
        "adherenceScore": adherence,
        "burnoutRiskScore": round(burnout_score, 3),
        "recoveryScore": round(recovery, 3),
    }
    result = await dotnet.patch_ai_context(ctx.user_id, patch)
    return {"updated": patch, "iam": result}


_TIME_OF_DAY_DEFAULTS = {
    "sang": "06:30",
    "morning": "06:30",
    "trua": "12:00",
    "noon": "12:00",
    "lunch": "12:00",
    "chieu": "17:00",
    "afternoon": "17:00",
    "toi": "19:30",
    "evening": "19:30",
    "night": "19:30",
}

_ZERO_GUID = "00000000-0000-0000-0000-000000000000"

# .NET SessionStatus (JsonStringEnumConverter) chỉ nhận đúng 4 tên này —
# chuỗi khác ("in_progress", "planned", "done"...) → 400 "Validation failed."
_SESSION_STATUS_CANON = {
    "scheduled": "Scheduled",
    "completed": "Completed",
    "skipped": "Skipped",
    "inprogress": "InProgress",
}


def _norm_session_status(value: Any) -> str:
    key = str(value or "").strip().replace("-", "").replace("_", "").replace(" ", "").lower()
    return _SESSION_STATUS_CANON.get(key, "Scheduled")


# Luật đổi giờ buổi tập qua AI: chỉ trong CÙNG NGÀY, giờ mới phải TRƯỚC 22:00
# (sau 22:00 không nhận — buổi tối muộn ảnh hưởng giấc ngủ/phục hồi).
_RESCHEDULE_LATEST_TIME = "22:00"


def _parse_hhmm(value: Any) -> tuple[int, int] | None:
    import re as _re2
    m = _re2.fullmatch(r"(\d{1,2}):(\d{2})", str(value or "").strip())
    if not m:
        return None
    h, mi = int(m.group(1)), int(m.group(2))
    if h > 23 or mi > 59:
        return None
    return h, mi


def validate_time_change(
    *,
    current_date: str,
    new_date: str,
    new_time: str,
) -> str | None:
    """Trả message lỗi (tiếng Việt, nói được với user) nếu vi phạm luật đổi lịch;
    None nếu hợp lệ. current_date/new_date dạng YYYY-MM-DD (new_date rỗng = giữ ngày)."""
    hm = _parse_hhmm(new_time)
    if hm is None:
        return f"Giờ '{new_time}' không hợp lệ — dùng dạng HH:MM (vd 06:30, 18:00)."
    cutoff = _parse_hhmm(_RESCHEDULE_LATEST_TIME)
    assert cutoff is not None
    if hm >= cutoff:
        return (
            f"Không đổi được sang {new_time} — buổi tập chỉ được xếp TRƯỚC "
            f"{_RESCHEDULE_LATEST_TIME} trong ngày. Chọn giờ sớm hơn giúp mình nhé."
        )
    cur = str(current_date or "")[:10]
    nxt = str(new_date or "")[:10]
    if cur and nxt and nxt != cur:
        return (
            "Mình chỉ hỗ trợ đổi GIỜ trong cùng ngày của buổi tập "
            f"({cur}). Muốn dời sang ngày khác thì bạn chỉnh trong tab Workout giúp mình."
        )
    return None


def _normalize_time_of_day(value: str | None) -> str | None:
    if not value:
        return None
    key = "".join(ch for ch in value.lower().strip() if ch.isalnum())
    # strip accents roughly for matching keys above
    for src, dst in (("áàảãạăắằẳẵặâấầẩẫậ", "a"), ("éèẻẽẹêếềểễệ", "e"),
                     ("íìỉĩị", "i"), ("óòỏõọôốồổỗộơớờởỡợ", "o"),
                     ("úùủũụưứừửữự", "u"), ("ýỳỷỹỵ", "y"), ("đ", "d")):
        for c in src:
            key = key.replace(c, dst)
    return _TIME_OF_DAY_DEFAULTS.get(key)


def resolve_plan_window(
    *,
    horizon: str = "week",
    days: int = 7,
    from_date: str = "",
    to_date: str = "",
    week_start_date: str = "",
    target_slots: list[dict[str, Any]] | None = None,
    today: date | None = None,
) -> dict[str, Any]:
    """Resolve horizon/slots → date window + concrete slots with HH:MM."""
    today = today or date.today()
    horizon = (horizon or "week").strip().lower()
    slots_in = list(target_slots or [])

    def _parse_d(s: str) -> date | None:
        try:
            return date.fromisoformat(s[:10])
        except ValueError:
            return None

    resolved_slots: list[dict[str, str]] = []
    for raw in slots_in:
        if not isinstance(raw, dict):
            continue
        d = _parse_d(str(raw.get("date") or ""))
        if d is None:
            continue
        t = (raw.get("time") or "").strip()
        if not t:
            t = _normalize_time_of_day(str(raw.get("time_of_day") or "")) or "07:00"
        resolved_slots.append({"date": d.isoformat(), "time": t})

    if resolved_slots or horizon == "slots":
        if not resolved_slots:
            resolved_slots = [{"date": today.isoformat(), "time": "07:00"}]
        dates = sorted({s["date"] for s in resolved_slots})
        return {
            "horizon": "slots",
            "from_date": dates[0],
            "to_date": dates[-1],
            "slots": resolved_slots,
            "suggested_session_count": len(resolved_slots),
        }

    if horizon == "today":
        return {
            "horizon": "today",
            "from_date": today.isoformat(),
            "to_date": today.isoformat(),
            "slots": [{"date": today.isoformat(), "time": "07:00"}],
            "suggested_session_count": 1,
        }

    if horizon == "next_n_days":
        n = max(1, min(int(days or 7), 21))
        end = today + timedelta(days=n - 1)
        return {
            "horizon": "next_n_days",
            "from_date": today.isoformat(),
            "to_date": end.isoformat(),
            "slots": [],
            "suggested_session_count": max(2, min(n // 2 + 1, 5)),
        }

    if horizon == "rest_of_week":
        # "Từ hôm nay đến hết tuần" = hôm nay → Chủ Nhật tuần NÀY (không phải +7 ngày).
        sunday = today + timedelta(days=6 - today.weekday())
        span = (sunday - today).days + 1
        return {
            "horizon": "rest_of_week",
            "from_date": today.isoformat(),
            "to_date": sunday.isoformat(),
            "slots": [],
            "suggested_session_count": max(1, min(span, 5)),
        }

    if horizon == "range" and from_date and to_date:
        fd = _parse_d(from_date) or today
        td = _parse_d(to_date) or fd
        if td < fd:
            fd, td = td, fd
        span = (td - fd).days + 1
        return {
            "horizon": "range",
            "from_date": fd.isoformat(),
            "to_date": td.isoformat(),
            "slots": [],
            "suggested_session_count": max(2, min(span // 2 + 1, 6)),
        }

    # week (default)
    if week_start_date:
        week_start = _parse_d(week_start_date) or today
    else:
        monday = today - timedelta(days=today.weekday())
        # If today is still within this week Mon–Sun, use current week; else next Monday.
        week_start = monday if today <= monday + timedelta(days=6) else monday + timedelta(days=7)
    week_end = week_start + timedelta(days=6)
    return {
        "horizon": "week",
        "from_date": week_start.isoformat(),
        "to_date": week_end.isoformat(),
        "slots": [],
        "suggested_session_count": 4,
    }


def _suggested_session_count(window: Mapping[str, Any], sessions_per_day: int = 1) -> int:
    """Số buổi planner nên tạo. User nói 'k buổi/ngày' → k × số ngày trong window
    (không dùng default 4 — từng gây thiếu buổi khi user yêu cầu 2 buổi/ngày)."""
    base = int(window.get("suggested_session_count") or 4)
    spd = max(1, min(int(sessions_per_day or 1), 3))
    if spd <= 1:
        return base
    try:
        fd = date.fromisoformat(str(window.get("from_date") or "")[:10])
        td = date.fromisoformat(str(window.get("to_date") or "")[:10])
        num_days = max(1, (td - fd).days + 1)
    except ValueError:
        num_days = max(1, base)
    return min(num_days * spd, 16)


def _extract_items(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return [x for x in payload if isinstance(x, dict)]
    if isinstance(payload, dict):
        items = payload.get("items")
        if isinstance(items, list):
            return [x for x in items if isinstance(x, dict)]
        # single object masquerading as dict without items
        if payload.get("id") or payload.get("startedAt"):
            return [payload]
    return []


def _execution_detail(item: dict[str, Any]) -> dict[str, Any]:
    started = item.get("startedAt") or item.get("StartedAt") or ""
    sets_raw = item.get("sets") or item.get("Sets") or []
    sets: list[dict[str, Any]] = []
    if isinstance(sets_raw, list):
        for s in sets_raw:
            if not isinstance(s, dict):
                continue
            sets.append({
                "exerciseId": s.get("exerciseId") or s.get("ExerciseId"),
                "setNumber": s.get("setNumber") or s.get("SetNumber"),
                "targetReps": s.get("targetReps") or s.get("TargetReps"),
                "actualReps": s.get("actualReps") or s.get("ActualReps"),
                "weightKg": s.get("weightKg") if s.get("weightKg") is not None else s.get("WeightKg"),
                "rir": s.get("rir") if s.get("rir") is not None else s.get("Rir"),
                "formScore": s.get("formScore") if s.get("formScore") is not None else s.get("FormScore"),
            })
    return {
        "date": str(started)[:10],
        "sessionId": item.get("sessionId") or item.get("SessionId"),
        "sessionType": item.get("sessionType") or item.get("SessionType"),
        "completionRate": item.get("completionRate") if item.get("completionRate") is not None else item.get("CompletionRate"),
        "perceivedDifficulty": item.get("perceivedDifficulty") if item.get("perceivedDifficulty") is not None else item.get("PerceivedDifficulty"),
        "energyLevelBefore": item.get("energyLevelBefore") if item.get("energyLevelBefore") is not None else item.get("EnergyLevelBefore"),
        "energyLevelAfter": item.get("energyLevelAfter") if item.get("energyLevelAfter") is not None else item.get("EnergyLevelAfter"),
        "caloriesBurned": item.get("caloriesBurned") if item.get("caloriesBurned") is not None else item.get("CaloriesBurned"),
        "actualDurationMinutes": item.get("actualDurationMinutes") if item.get("actualDurationMinutes") is not None else item.get("ActualDurationMinutes"),
        "skippedExercises": item.get("skippedExercises") or item.get("SkippedExercises") or [],
        "sets": sets,
    }


async def assemble_workout_plan_context(
    ctx: ToolRunContext,
    *,
    window: dict[str, Any],
    mode: str = "create",
    session_id: str = "",
) -> dict[str, Any]:
    """Full context bundle for LLM plan/edit (tool-first, no invented numbers)."""
    today = local_today(ctx)
    tz = resolve_tz_name(ctx)
    uid = ctx.user_id
    roadmap_task = dotnet.get_active_roadmap(uid)
    recovery_task = dotnet.get_recovery_status(uid)
    exec7_task = dotnet.get_workout_executions_range(
        uid,
        from_iso=(today - timedelta(days=7)).isoformat(),
        to_iso=today.isoformat(),
        time_zone_id=tz,
    )
    exec28_task = dotnet.get_workout_executions_range(
        uid,
        from_iso=(today - timedelta(days=28)).isoformat(),
        to_iso=today.isoformat(),
        time_zone_id=tz,
    )
    sessions_task = None
    if mode == "edit" or session_id:
        sessions_task = dotnet.get_sessions_by_range(
            uid,
            from_iso=window["from_date"],
            to_iso=window["to_date"],
            time_zone_id=tz,
        )

    if sessions_task is not None:
        roadmap_data, recovery_data, exec7, exec28, existing = await asyncio.gather(
            roadmap_task, recovery_task, exec7_task, exec28_task, sessions_task,
        )
    else:
        roadmap_data, recovery_data, exec7, exec28 = await asyncio.gather(
            roadmap_task, recovery_task, exec7_task, exec28_task,
        )
        existing = {"items": []}

    snapshot = ctx.state.get("user_snapshot") or {}
    roadmap = roadmap_data if isinstance(roadmap_data, dict) else {}
    recovery = recovery_data if isinstance(recovery_data, dict) else {}

    exec7_items = [_execution_detail(x) for x in _extract_items(exec7)]
    exec28_count = len(_extract_items(exec28))

    existing_sessions = _extract_items(existing)
    if session_id:
        existing_sessions = [
            s for s in existing_sessions
            if str(s.get("id") or s.get("Id") or "") == session_id
        ] or existing_sessions

    return {
        "window": window,
        "roadmap": {
            "id": roadmap.get("id") or roadmap.get("Id"),
            "fitnessGoal": roadmap.get("fitnessGoal") or snapshot.get("fitnessGoal") or "Maintain",
            "currentPhase": roadmap.get("currentPhase") or "Foundation",
            "targetWeightKg": roadmap.get("targetWeightKg") or snapshot.get("targetWeightKg"),
            "targetFatPercentage": roadmap.get("targetFatPercentage") or snapshot.get("goalBodyFatPercentage"),
            "allowAiReschedule": roadmap.get("allowAiReschedule"),
            "allowAiIntensityAdjustment": roadmap.get("allowAiIntensityAdjustment"),
            "allowAiRecoveryDeload": roadmap.get("allowAiRecoveryDeload"),
        },
        "biometrics": {
            "gender": snapshot.get("gender"),
            "heightCm": snapshot.get("heightCm"),
            "currentWeightKg": snapshot.get("currentWeightKg") or roadmap.get("currentWeightKg"),
            "targetWeightKg": snapshot.get("targetWeightKg") or roadmap.get("targetWeightKg"),
            "currentBodyFatPercentage": snapshot.get("currentBodyFatPercentage") or roadmap.get("initialFatPercentage"),
            "goalBodyFatPercentage": snapshot.get("goalBodyFatPercentage") or roadmap.get("targetFatPercentage"),
            "muscleMassKg": snapshot.get("muscleMassKg"),
            "baseTDEE": snapshot.get("baseTDEE"),
            "bmr": snapshot.get("bmr"),
            "dailyProteinTargetGram": snapshot.get("dailyProteinTargetGram"),
            "dailyCarbTargetGram": snapshot.get("dailyCarbTargetGram"),
            "dailyFatTargetGram": snapshot.get("dailyFatTargetGram"),
            "activityLevel": snapshot.get("activityLevel"),
            "experienceLevel": snapshot.get("experienceLevel"),
            "workoutLocationPreference": snapshot.get("workoutLocationPreference"),
        },
        "recovery": {
            "currentRecoveryScore": recovery.get("currentRecoveryScore"),
            "fatigueLevel": recovery.get("fatigueLevel"),
            "muscleSorenessScore": recovery.get("muscleSorenessScore"),
            "cnsFatigueScore": recovery.get("cnsFatigueScore"),
            "recommendedTrainingIntensity": recovery.get("recommendedTrainingIntensity"),
            "recommendedWorkoutDuration": recovery.get("recommendedWorkoutDuration"),
        },
        "constraints": {
            "injuries": snapshot.get("injuries") or [],
            "medications": snapshot.get("medications") or [],
            "allergies": snapshot.get("allergies") or [],
        },
        "executions_last_7_days": exec7_items,
        "executions_last_28_days_count": exec28_count,
        "existing_sessions": existing_sessions,
    }


def _exercise_lookup_queries(name: str) -> list[str]:
    """Generate search strings: full name → strip parens/weights → tokens ≥3 chars."""
    import re

    raw = (name or "").strip()
    if not raw:
        return []
    queries: list[str] = []
    seen: set[str] = set()

    def _add(q: str) -> None:
        q = q.strip()
        if not q:
            return
        key = q.lower()
        if key in seen:
            return
        seen.add(key)
        queries.append(q)

    _add(raw)
    # Drop parenthetical qualifiers: "Squat (bodyweight)" → "Squat"
    no_paren = re.sub(r"\([^)]*\)", " ", raw)
    no_paren = re.sub(r"\s+", " ", no_paren).strip()
    _add(no_paren)
    # Strip trailing sets/reps-ish tokens: "Bench Press 3x10" → "Bench Press"
    no_reps = re.sub(
        r"\b\d+\s*[x×]\s*\d+\b|\b\d+\s*(kg|lbs?|reps?|sets?)\b",
        " ",
        no_paren,
        flags=re.IGNORECASE,
    )
    no_reps = re.sub(r"\s+", " ", no_reps).strip()
    _add(no_reps)
    for token in re.split(r"[\s/,\-]+", no_reps):
        t = token.strip(" .,:;+()")
        if len(t) >= 3 and not t.isdigit():
            _add(t)
    return queries


async def resolve_exercise_ids(user_id: str, sessions: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Replace placeholder/missing exerciseId with catalog Ids via search_exercises.

    Unresolved blocks are dropped. Failed names are collected on
    ``resolve_exercise_ids.last_unresolved`` for caller error messages.
    """
    cache: dict[str, tuple[str, str] | None] = {}

    async def _lookup(name: str) -> tuple[str, str] | None:
        key = (name or "").strip().lower()
        if not key:
            return None
        if key in cache:
            return cache[key]
        try:
            result = await dotnet.search_exercises(user_id, query=name, limit=3)
        except Exception:
            cache[key] = None
            return None
        items = _extract_items(result)
        if not items and isinstance(result, dict):
            raw = result.get("value")
            if isinstance(raw, list):
                items = [x for x in raw if isinstance(x, dict)]
        for it in items:
            eid = str(it.get("id") or it.get("Id") or "")
            ename = str(
                it.get("nameEn")
                or it.get("nameVi")
                or it.get("name")
                or it.get("NameEn")
                or it.get("NameVi")
                or it.get("Name")
                or name
            )
            if eid and eid != _ZERO_GUID:
                cache[key] = (eid, ename)
                return cache[key]
        cache[key] = None
        return None

    async def _resolve_name(name: str) -> tuple[str, str] | None:
        for q in _exercise_lookup_queries(name):
            hit = await _lookup(q)
            if hit:
                return hit
        return None

    out: list[dict[str, Any]] = []
    global_unresolved: list[str] = []
    for sess in sessions:
        blocks_in = sess.get("executionBlocks") or []
        blocks_out: list[dict[str, Any]] = []
        unresolved: list[str] = []
        for i, b in enumerate(blocks_in):
            if not isinstance(b, dict):
                continue
            name = str(b.get("exerciseName") or b.get("ExerciseName") or "")
            eid = str(b.get("exerciseId") or b.get("ExerciseId") or "")
            if not eid or eid == _ZERO_GUID:
                hit = await _resolve_name(name)
                if hit:
                    eid, resolved_name = hit
                    name = resolved_name or name
                else:
                    if name:
                        unresolved.append(name)
                        global_unresolved.append(name)
                    continue  # drop unresolved block — never keep GUID 0
            blocks_out.append({
                "order": b.get("order", i + 1),
                "exerciseId": eid,
                "exerciseName": name,
                "targetSets": b.get("targetSets", 3),
                "targetReps": b.get("targetReps", 10),
                "targetWeightKg": b.get("targetWeightKg", 0),
                "restSeconds": b.get("restSeconds", 60),
                "tempo": b.get("tempo", "2-0-2"),
            })
        if not blocks_out and blocks_in:
            continue
        sess_out = dict(sess)
        sess_out["executionBlocks"] = blocks_out
        if unresolved:
            sess_out["_unresolved_exercises"] = unresolved
        out.append(sess_out)
    resolve_exercise_ids.last_unresolved = list(dict.fromkeys(global_unresolved))  # type: ignore[attr-defined]
    return out


resolve_exercise_ids.last_unresolved = []  # type: ignore[attr-defined]


def _sessions_to_schedule_payload(
    user_id: str,
    roadmap_id: str,
    sessions: list[dict[str, Any]],
    default_duration: int = 45,
    *,
    timezone_id: str = DEFAULT_TZ,
) -> list[dict[str, Any]]:
    payload: list[dict[str, Any]] = []
    for s in sessions:
        if str(s.get("sessionType", "")).lower() == "rest":
            continue
        blocks = s.get("executionBlocks") or []
        # Never forward internal resolve meta keys to Roadmap API
        clean_blocks = []
        for b in blocks:
            if not isinstance(b, dict):
                continue
            clean_blocks.append({
                k: v for k, v in b.items()
                if not str(k).startswith("_")
            })
        payload.append({
            "userId": user_id,
            "roadmapId": roadmap_id or None,
            "scheduledDate": s.get("date") or s.get("scheduledDate"),
            "scheduledTime": s.get("time") or s.get("scheduledTime") or "07:00",
            "timezone": timezone_id or DEFAULT_TZ,
            "sessionTitle": s.get("sessionTitle", "Buổi tập"),
            "sessionType": s.get("sessionType", "Strength"),
            "estimatedDurationMinutes": s.get("estimatedDurationMinutes", default_duration),
            "notificationEnabled": True,
            "notificationMinutesBefore": 30,
            "executionBlocks": clean_blocks,
        })
    return payload


# Khung giờ gán cho các buổi trùng giờ trong cùng ngày (buổi đầu giữ giờ gốc).
_DAY_TIME_SLOTS = ("06:30", "19:30", "12:00", "16:00")


def _spread_session_times(sessions: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """≥2 buổi cùng ngày không được trùng giờ.

    LLM planner hay đặt mọi buổi vào cùng preferred time (vd 19:30). Buổi đầu
    của mỗi ngày giữ giờ nó khai; các buổi sau nếu trùng/thiếu giờ được gán
    slot còn trống theo _DAY_TIME_SLOTS.
    """
    by_date: dict[str, list[dict[str, Any]]] = {}
    for s in sessions:
        if not isinstance(s, dict):
            continue
        d = str(s.get("date") or s.get("scheduledDate") or "")[:10]
        by_date.setdefault(d, []).append(s)
    for group in by_date.values():
        if len(group) < 2:
            continue
        seen: set[str] = set()
        for s in group:
            t = str(s.get("time") or s.get("scheduledTime") or "").strip()[:5]
            if not t or t in seen:
                t = next((x for x in _DAY_TIME_SLOTS if x not in seen), t or "07:00")
            seen.add(t)
            s["time"] = t
            if "scheduledTime" in s:
                s["scheduledTime"] = t
    return sessions


def _roadmap_allows_ai_reschedule(roadmap: Mapping[str, Any] | None) -> bool:
    if not isinstance(roadmap, Mapping):
        return False
    v = roadmap.get("allowAiReschedule")
    if v is None:
        v = roadmap.get("AllowAiReschedule")
    return bool(v)


def _session_ids_from_schedule_result(result: Any) -> list[str]:
    """Extract RoadmapSession ids from schedule_week / update responses."""
    ids: list[str] = []

    def _from_item(item: Any) -> None:
        if not isinstance(item, dict):
            return
        session = item.get("session") or item.get("Session") or item
        if not isinstance(session, dict):
            return
        sid = session.get("id") or session.get("Id") or item.get("sessionId") or item.get("SessionId")
        if sid:
            ids.append(str(sid))

    if isinstance(result, list):
        for item in result:
            _from_item(item)
    elif isinstance(result, dict):
        items = result.get("items") or result.get("Items")
        if isinstance(items, list):
            for item in items:
                _from_item(item)
        else:
            _from_item(result)
    return ids


def _plan_date_window(action: Mapping[str, Any]) -> tuple[str, str]:
    """Best-effort from/to dates for post-write schedule verification."""
    dates: list[str] = []
    mode = str(action.get("mode") or "create").strip().lower()
    if mode == "edit":
        ops = action.get("ops") if isinstance(action.get("ops"), dict) else {}
        for s in list(ops.get("add") or []) + list(ops.get("update") or []):
            if isinstance(s, dict):
                d = s.get("scheduledDate") or s.get("date") or s.get("ScheduledDate")
                if d:
                    dates.append(str(d)[:10])
        for r in ops.get("reschedule") or []:
            if isinstance(r, dict):
                d = r.get("newDate") or r.get("new_date")
                if d:
                    dates.append(str(d)[:10])
    else:
        for s in action.get("sessions") or []:
            if isinstance(s, dict):
                d = s.get("scheduledDate") or s.get("date") or s.get("ScheduledDate")
                if d:
                    dates.append(str(d)[:10])
    if not dates:
        today = date.today().isoformat()
        return today, today
    return min(dates), max(dates)


async def _verify_saved_sessions(
    user_id: str,
    action: Mapping[str, Any],
    *,
    saved_session_ids: list[str],
) -> dict[str, Any]:
    """Re-read schedule for the plan window; confirm sessions exist in Roadmap."""
    from_d, to_d = _plan_date_window(action)
    try:
        schedule = await dotnet.get_sessions_by_range(
            user_id, from_iso=from_d, to_iso=to_d,
        )
    except Exception as exc:
        return {
            "verified": False,
            "verify_error": str(exc),
            "from_date": from_d,
            "to_date": to_d,
            "saved_session_ids": saved_session_ids,
        }

    items = []
    if isinstance(schedule, dict):
        raw = schedule.get("items") or schedule.get("Items") or schedule.get("sessions") or []
        if isinstance(raw, list):
            items = raw
    elif isinstance(schedule, list):
        items = schedule

    found_ids: list[str] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        sid = item.get("id") or item.get("Id")
        if not sid and isinstance(item.get("session") or item.get("Session"), dict):
            sess = item.get("session") or item.get("Session")
            sid = sess.get("id") or sess.get("Id")
        if sid:
            found_ids.append(str(sid))

    verified = bool(found_ids) or bool(saved_session_ids)
    return {
        "verified": verified,
        "from_date": from_d,
        "to_date": to_d,
        "saved_session_ids": saved_session_ids or found_ids,
        "schedule_count": len(found_ids),
    }


async def execute_workout_plan_write(user_id: str, action: Mapping[str, Any]) -> dict[str, Any]:
    """Persist create/edit workout plan to Roadmap (shared by tool + confirm)."""
    mode = str(action.get("mode") or "create").strip().lower()
    saved_session_ids: list[str] = []

    def _valid_guid(eid: Any) -> bool:
        s = str(eid or "").strip()
        if not s or s == _ZERO_GUID:
            return False
        import re
        return bool(re.fullmatch(
            r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
            s,
        ))

    def _sanitize_blocks(blocks: Any) -> list[dict[str, Any]]:
        out: list[dict[str, Any]] = []
        for i, b in enumerate(blocks or []):
            if not isinstance(b, dict):
                continue
            eid = b.get("exerciseId") or b.get("ExerciseId")
            if not _valid_guid(eid):
                continue
            out.append({
                "order": b.get("order", i + 1),
                "exerciseId": str(eid),
                "exerciseName": b.get("exerciseName") or b.get("ExerciseName") or "Exercise",
                "targetSets": b.get("targetSets", 3),
                "targetReps": b.get("targetReps", 10),
                "targetWeightKg": b.get("targetWeightKg", 0),
                "restSeconds": b.get("restSeconds", 60),
                "tempo": b.get("tempo", "2-0-2"),
            })
        return out

    if mode == "edit":
        ops = action.get("ops") or {}
        if not isinstance(ops, dict):
            ops = {}
        results: dict[str, Any] = {
            "added": [], "updated": [], "rescheduled": [], "removed": [],
        }
        add_sessions = []
        for s in ops.get("add") or []:
            if not isinstance(s, dict):
                continue
            s2 = dict(s)
            s2["executionBlocks"] = _sanitize_blocks(s.get("executionBlocks"))
            if not s2["executionBlocks"]:
                continue
            add_sessions.append(s2)
        if add_sessions:
            try:
                added = await dotnet.schedule_week(user_id, list(add_sessions))
            except dotnet.DotnetApiError as exc:
                msg = (exc.message or "").lower()
                if exc.status_code == 400 and (
                    "disabled" in msg or "allowaireschedule" in msg or "ai reschedule" in msg
                ):
                    return {
                        "status": "error",
                        "mode": "edit",
                        "reason": "ai_reschedule_disabled",
                        "message": (
                            "Lộ trình đang tắt quyền cho AI chỉnh lịch. "
                            "Bật 'Cho phép AI đổi lịch' rồi thử lại nhé."
                        ),
                    }
                return {
                    "status": "error",
                    "mode": "edit",
                    "message": f"Không lưu được buổi mới: {exc.message}",
                }
            results["added"] = added
            saved_session_ids.extend(_session_ids_from_schedule_result(added))
        for u in ops.get("update") or []:
            if not isinstance(u, dict):
                continue
            sid = str(u.get("sessionId") or "")
            if not _valid_guid(sid):
                continue
            blocks = _sanitize_blocks(u.get("executionBlocks"))
            if not blocks:
                return {
                    "status": "error",
                    "message": (
                        "Không lưu được: buổi cập nhật không còn bài tập hợp lệ trong thư viện "
                        "(exerciseId thiếu hoặc không resolve được)."
                    ),
                    "mode": "edit",
                }
            # .NET UpdateRoadmapSessionDto: scheduledDate là DateTimeOffset non-nullable
            # (null → 400 binding), sessionStatus là enum 4 giá trị (chuỗi khác → 400),
            # sessionTitle rỗng → BadRequestException. Chuẩn hoá trước khi gửi.
            sched_date = u.get("scheduledDate") or u.get("date")
            if not sched_date:
                sched_date, _ = _plan_date_window(action)
            payload = {
                "scheduledDate": sched_date,
                "scheduledTime": u.get("scheduledTime") or u.get("time") or "07:00",
                "timezone": u.get("timezone") or DEFAULT_TZ,
                "sessionType": u.get("sessionType") or "Strength",
                "sessionTitle": str(u.get("sessionTitle") or "").strip() or "Buổi tập",
                "estimatedDurationMinutes": int(u.get("estimatedDurationMinutes") or 45),
                "energyDemandScore": int(u.get("energyDemandScore") or 5),
                "recoveryRequirementScore": int(u.get("recoveryRequirementScore") or 5),
                "notificationEnabled": True,
                "notificationMinutesBefore": 30,
                "aiGenerated": True,
                "sessionStatus": _norm_session_status(u.get("sessionStatus")),
                "executionBlocks": blocks,
            }
            # roadmapId non-nullable Guid: chỉ gửi khi là GUID thật (absent → Guid.Empty
            # → .NET bỏ qua gate); null → 400 binding.
            rid = action.get("roadmap_id") or u.get("roadmapId")
            if _valid_guid(rid):
                payload["roadmapId"] = str(rid)
            try:
                updated = await dotnet.update_roadmap_session(user_id, sid, payload)
            except dotnet.DotnetApiError as exc:
                if exc.status_code == 400 and "disabled" in (exc.message or "").lower():
                    return {
                        "status": "error",
                        "mode": "edit",
                        "reason": "ai_edit_disabled",
                        "message": (
                            "Lộ trình đang tắt quyền cho AI chỉnh lịch. "
                            "Bật 'Cho phép AI đổi lịch' rồi thử lại nhé."
                        ),
                    }
                return {
                    "status": "error",
                    "mode": "edit",
                    "message": f"Không lưu được buổi '{payload['sessionTitle']}': {exc.message}",
                }
            results["updated"].append(updated)
            saved_session_ids.append(sid)
            saved_session_ids.extend(_session_ids_from_schedule_result(updated))
        for r in ops.get("reschedule") or []:
            if not isinstance(r, dict):
                continue
            sid = str(r.get("sessionId") or "")
            new_date = str(r.get("newDate") or r.get("new_date") or "")
            new_time = str(r.get("newTime") or r.get("new_time") or "07:00")
            # Luật đổi lịch qua AI: cùng ngày + trước 22:00 (đọc ngày thật của buổi).
            current_date = ""
            try:
                sess = await dotnet.get_roadmap_session(user_id, sid)
                current_date = str(
                    sess.get("scheduledDate") or sess.get("ScheduledDate") or ""
                )[:10]
            except Exception:
                pass
            if not new_date and current_date:
                new_date = current_date
            err = validate_time_change(
                current_date=current_date, new_date=new_date, new_time=new_time,
            )
            if err:
                return {"status": "error", "mode": "edit", "message": err}
            results["rescheduled"].append(
                await dotnet.reschedule_session(user_id, sid, new_date, new_time)
            )
            if sid:
                saved_session_ids.append(sid)
        for rid in ops.get("remove") or []:
            results["removed"].append(
                await dotnet.delete_roadmap_session(user_id, str(rid))
            )
        seen: set[str] = set()
        uniq: list[str] = []
        for x in saved_session_ids:
            if x and x not in seen:
                seen.add(x)
                uniq.append(x)
        verify = await _verify_saved_sessions(user_id, action, saved_session_ids=uniq)
        return {"edited": results, "mode": "edit", **verify}

    sessions_raw = list(action.get("sessions") or [])
    sessions: list[dict[str, Any]] = []
    for s in sessions_raw:
        if not isinstance(s, dict):
            continue
        s2 = dict(s)
        s2["executionBlocks"] = _sanitize_blocks(s.get("executionBlocks"))
        if str(s2.get("sessionType", "")).lower() == "rest" or s2["executionBlocks"]:
            sessions.append(s2)
    if not sessions:
        return {
            "status": "error",
            "message": "Không có buổi tập hợp lệ để lưu (thiếu exerciseId trong catalog).",
            "mode": "create",
        }
    try:
        result = await dotnet.schedule_week(user_id, sessions)
    except dotnet.DotnetApiError as exc:
        msg = (exc.message or "").lower()
        if exc.status_code == 400 and ("disabled" in msg or "allowaireschedule" in msg or "ai reschedule" in msg):
            return {
                "status": "error",
                "mode": "create",
                "reason": "ai_reschedule_disabled",
                "message": (
                    "Lộ trình đang tắt quyền cho AI chỉnh lịch. "
                    "Bật 'Cho phép AI đổi lịch' (hoặc xác nhận card bật quyền) rồi thử lại nhé."
                ),
            }
        return {
            "status": "error",
            "mode": "create",
            "message": f"Không lưu được lịch tập: {exc.message}",
        }
    saved_session_ids = _session_ids_from_schedule_result(result)
    verify = await _verify_saved_sessions(user_id, action, saved_session_ids=saved_session_ids)
    if not verify.get("verified") and not saved_session_ids:
        return {
            "status": "error",
            "message": (
                "Đã gọi lưu lịch nhưng không thấy RoadmapSession sau khi đọc lại. "
                f"Khoảng {verify.get('from_date')}→{verify.get('to_date')}."
            ),
            "mode": "create",
            **verify,
        }
    return {"scheduled": result, "mode": "create", **verify}


def _enable_ai_reschedule_pending(
    *,
    action_id: str,
    roadmap_id: str,
    summary: str,
    staged: dict[str, Any],
) -> dict[str, Any]:
    return {
        "action_id": action_id,
        "type": "enable_ai_reschedule",
        "roadmap_id": roadmap_id,
        "summary": (
            "Bạn chưa bật quyền AI chỉnh lịch tập trên lộ trình. "
            "Xác nhận để cho phép và lưu lịch đã chuẩn bị."
        ),
        "plan_summary": summary,
        "staged_plan": staged,
        "status": "awaiting_confirmation",
    }


def _plan_or_edit_workout_pending(
    *,
    action_id: str,
    roadmap_id: str,
    summary: str,
    staged: dict[str, Any],
) -> dict[str, Any]:
    """HITL pending when AllowAiReschedule is already true — confirm then write."""
    mode = str(staged.get("mode") or "create")
    return {
        "action_id": action_id,
        "type": "plan_or_edit_workout",
        "roadmap_id": roadmap_id,
        "mode": mode,
        "summary": "Xác nhận để lưu lịch tập vào lộ trình.",
        "plan_summary": summary,
        "staged_plan": staged,
        "sessions": staged.get("sessions"),
        "ops": staged.get("ops"),
        "status": "awaiting_confirmation",
    }


def _format_block_line(block: dict[str, Any]) -> str:
    name = str(block.get("exerciseName") or block.get("ExerciseName") or "Bài tập")
    sets = block.get("targetSets", block.get("TargetSets"))
    reps = block.get("targetReps", block.get("TargetReps"))
    weight = block.get("targetWeightKg", block.get("TargetWeightKg"))
    parts = [name]
    if sets is not None and reps is not None:
        parts.append(f"{sets}x{reps}")
    elif sets is not None:
        parts.append(f"{sets} set")
    if weight not in (None, "", 0, 0.0):
        parts.append(f"{weight}kg")
    return " · ".join(str(p) for p in parts)


def format_sessions_prose(
    sessions: list[dict[str, Any]],
    *,
    window: dict[str, Any] | None = None,
    reason: str = "",
    ask_confirm: bool = True,
) -> str:
    """Human-readable schedule for chat — no raw JSON keys."""
    lines: list[str] = []
    if window:
        lines.append(
            f"Lịch {window.get('from_date')} → {window.get('to_date')} "
            f"({window.get('horizon', 'week')}): {len(sessions)} buổi."
        )
    for s in sessions:
        if not isinstance(s, dict):
            continue
        if str(s.get("sessionType", "")).lower() == "rest":
            continue
        title = s.get("sessionTitle") or "Buổi tập"
        day = s.get("date") or s.get("scheduledDate") or ""
        time = s.get("time") or s.get("scheduledTime") or ""
        dur = s.get("estimatedDurationMinutes")
        head = f"{day} {time}".strip()
        dur_s = f", khoảng {dur} phút" if dur else ""
        lines.append(f"{head}: {title}{dur_s}.")
        blocks = s.get("executionBlocks") or []
        for b in blocks:
            if isinstance(b, dict):
                lines.append(f"  - {_format_block_line(b)}")
    if reason and reason.strip():
        lines.append(reason.strip())
    if ask_confirm:
        lines.append("Bạn xác nhận để lưu lịch này không?")
    return "\n".join(lines)


def apply_explicit_edit_overrides(
    sessions: list[dict[str, Any]],
    edit_intent: str,
) -> list[dict[str, Any]]:
    """Force targetSets/reps/kg from explicit user phrases onto matching blocks."""
    import re

    intent = strip_accents((edit_intent or "").lower())
    if not intent:
        return sessions

    set_m = re.search(r"(\d+)\s*set", intent)
    rep_m = re.search(r"(\d+)\s*(?:rep|reps|lan)", intent)
    kg_m = re.search(r"(\d+(?:\.\d+)?)\s*kg", intent)
    target_sets = int(set_m.group(1)) if set_m else None
    target_reps = int(rep_m.group(1)) if rep_m else None
    target_kg = float(kg_m.group(1)) if kg_m else None
    if target_sets is None and target_reps is None and target_kg is None:
        return sessions

    # Exercise name candidates: tokens before "chi"/"set"/"xuong"/numbers
    name_hint = intent
    for sep in (" chi ", " con ", " xuong ", " thanh ", " set", " rep", " kg"):
        if sep in name_hint:
            name_hint = name_hint.split(sep)[0]
    name_hint = re.sub(r"\d+", " ", name_hint).strip()
    # Drop filler words
    for w in ("doi", "sua", "chinh", "giam", "tang", "bai", "tap", "thanh"):
        name_hint = re.sub(rf"\b{w}\b", " ", name_hint)
    name_hint = re.sub(r"\s+", " ", name_hint).strip()
    if len(name_hint) < 2:
        return sessions

    out: list[dict[str, Any]] = []
    for sess in sessions:
        if not isinstance(sess, dict):
            continue
        sess2 = dict(sess)
        blocks = []
        for b in sess.get("executionBlocks") or []:
            if not isinstance(b, dict):
                continue
            b2 = dict(b)
            ename = strip_accents(str(b2.get("exerciseName") or "").lower())
            if name_hint in ename or any(tok and tok in ename for tok in name_hint.split() if len(tok) >= 3):
                if target_sets is not None:
                    b2["targetSets"] = target_sets
                if target_reps is not None:
                    b2["targetReps"] = target_reps
                if target_kg is not None:
                    b2["targetWeightKg"] = target_kg
            blocks.append(b2)
        sess2["executionBlocks"] = blocks
        out.append(sess2)
    return out


def parse_substitute_intent(edit_intent: str) -> tuple[str, str] | None:
    """Parse 'thay A bằng B' / 'replace A with B' → (from_name, to_name)."""
    import re
    text = (edit_intent or "").strip()
    if not text:
        return None
    patterns = [
        r"(?:thay|đổi|doi|replace)\s+(.+?)\s+(?:bằng|bang|thành|thanh|with|by)\s+(.+)$",
        r"(?:substitute)\s+(.+?)\s+(?:with|for)\s+(.+)$",
    ]
    for p in patterns:
        m = re.search(p, text, flags=re.IGNORECASE)
        if m:
            a = re.sub(r"\s+", " ", m.group(1)).strip(" .,!")
            b = re.sub(r"\s+", " ", m.group(2)).strip(" .,!")
            # Trim trailing intent junk
            for junk in (" trong buổi", " hôm nay", " nhé", " giúp", " giúp mình", " please"):
                if b.lower().endswith(junk):
                    b = b[: -len(junk)].strip()
            if len(a) >= 2 and len(b) >= 2:
                return a, b
    return None


def regen_session_title(blocks: list[dict[str, Any]], *, hint: str = "") -> str:
    """Short title from block names + optional health hint."""
    names = [
        str(b.get("exerciseName") or "")
        for b in blocks
        if isinstance(b, dict) and b.get("exerciseName")
    ]
    hint_l = strip_accents((hint or "").lower())
    suffix = ""
    if any(k in hint_l for k in ("lung", "back", "lưng", "dau lung")):
        suffix = " (điều chỉnh lưng)"
    elif any(k in hint_l for k in ("vai", "shoulder", "dau vai")):
        suffix = " (điều chỉnh vai)"
    elif any(k in hint_l for k in ("dau", "pain", "chan thuong", "injury")):
        suffix = " (điều chỉnh)"
    if not names:
        return f"Buổi tập{suffix}"
    if len(names) <= 2:
        return f"{' + '.join(names)}{suffix}"[:80]
    return f"Full Body{suffix}"[:80]


async def apply_force_substitute(
    user_id: str,
    *,
    update_sessions: list[dict[str, Any]],
    existing_sessions: list[dict[str, Any]],
    from_name: str,
    to_name: str,
    edit_intent: str = "",
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    """Ensure replace A→B is reflected in update sessions (not remove-only).

    Returns (sessions, meta) where meta may include savable=False tip.
    """
    from_key = strip_accents(from_name.lower())
    to_key = strip_accents(to_name.lower())
    meta: dict[str, Any] = {"from": from_name, "to": to_name, "savable": True}

    # Resolve replacement exercise in catalog
    replacement: dict[str, Any] | None = None
    try:
        search = await dotnet.search_exercises(user_id, query=to_name, limit=5)
        for it in _extract_items(search):
            eid = str(it.get("id") or it.get("Id") or "")
            ename = str(it.get("nameEn") or it.get("nameVi") or it.get("name") or to_name)
            if eid and eid != _ZERO_GUID:
                replacement = {
                    "exerciseId": eid,
                    "exerciseName": ename,
                    "targetSets": 3,
                    "targetReps": 10,
                    "targetWeightKg": 0,
                    "restSeconds": 60,
                    "tempo": "2-0-2",
                }
                break
    except Exception:
        replacement = None

    if replacement is None:
        meta["savable"] = False
        meta["suggestion"] = to_name
        meta["message"] = (
            f"'{to_name}' chưa có trong thư viện bài tập Sync — đây là gợi ý để bạn tự tập, "
            "mình không lưu bài này vào lịch."
        )
        # Strip unsaved replacement names from updates; do not invent ops for B
        cleaned: list[dict[str, Any]] = []
        for sess in update_sessions:
            if not isinstance(sess, dict):
                continue
            s2 = dict(sess)
            blocks = []
            for b in sess.get("executionBlocks") or []:
                if not isinstance(b, dict):
                    continue
                ename = strip_accents(str(b.get("exerciseName") or "").lower())
                if to_key in ename or ename in to_key:
                    continue  # drop unresolved B
                blocks.append(dict(b))
            s2["executionBlocks"] = blocks
            cleaned.append(s2)
        return cleaned, meta

    # Build working set: prefer LLM updates; else clone matching existing sessions
    working = [dict(s) for s in update_sessions if isinstance(s, dict)]
    if not working:
        for ex in existing_sessions:
            if not isinstance(ex, dict):
                continue
            blocks = ex.get("executionBlocks") or ex.get("ExecutionBlocks") or []
            hit = False
            for b in blocks:
                if not isinstance(b, dict):
                    continue
                ename = strip_accents(str(b.get("exerciseName") or b.get("ExerciseName") or "").lower())
                if from_key in ename or ename in from_key:
                    hit = True
                    break
            if hit:
                working.append({
                    "sessionId": ex.get("id") or ex.get("sessionId") or ex.get("Id"),
                    "sessionTitle": ex.get("sessionTitle") or ex.get("SessionTitle"),
                    "sessionType": ex.get("sessionType") or ex.get("SessionType") or "Strength",
                    "estimatedDurationMinutes": ex.get("estimatedDurationMinutes") or 45,
                    "executionBlocks": [
                        {
                            "order": b.get("order", i + 1),
                            "exerciseId": str(b.get("exerciseId") or b.get("ExerciseId") or ""),
                            "exerciseName": b.get("exerciseName") or b.get("ExerciseName") or "",
                            "targetSets": b.get("targetSets", 3),
                            "targetReps": b.get("targetReps", 10),
                            "targetWeightKg": b.get("targetWeightKg", 0),
                            "restSeconds": b.get("restSeconds", 60),
                            "tempo": b.get("tempo", "2-0-2"),
                        }
                        for i, b in enumerate(blocks)
                        if isinstance(b, dict)
                    ],
                })

    out: list[dict[str, Any]] = []
    for sess in working:
        s2 = dict(sess)
        blocks_in = list(sess.get("executionBlocks") or [])
        blocks_out: list[dict[str, Any]] = []
        replaced = False
        for i, b in enumerate(blocks_in):
            if not isinstance(b, dict):
                continue
            ename = strip_accents(str(b.get("exerciseName") or "").lower())
            if from_key in ename or ename in from_key:
                nb = dict(replacement)
                nb["order"] = b.get("order", i + 1)
                nb["targetSets"] = b.get("targetSets", nb["targetSets"])
                nb["targetReps"] = b.get("targetReps", nb["targetReps"])
                nb["targetWeightKg"] = b.get("targetWeightKg", 0)
                nb["restSeconds"] = b.get("restSeconds", 60)
                blocks_out.append(nb)
                replaced = True
            else:
                # Drop accidental unresolved B name without id
                eid = str(b.get("exerciseId") or "")
                if (to_key in ename or ename in to_key) and (not eid or eid == _ZERO_GUID):
                    continue
                blocks_out.append(dict(b))
        if not replaced:
            # Append B if A wasn't found but intent is substitute (user insisting)
            nb = dict(replacement)
            nb["order"] = len(blocks_out) + 1
            blocks_out.append(nb)
        # Re-number
        for i, b in enumerate(blocks_out):
            b["order"] = i + 1
        s2["executionBlocks"] = blocks_out
        s2["sessionTitle"] = regen_session_title(blocks_out, hint=edit_intent or from_name)
        out.append(s2)
    return out, meta


async def plan_or_edit_workout(
    ctx: ToolRunContext,
    *,
    horizon: str = "week",
    days: int = 7,
    from_date: str = "",
    to_date: str = "",
    week_start_date: str = "",
    target_slots: list[dict[str, Any]] | None = None,
    sessions_per_day: int = 1,
    edit_intent: str = "",
    session_id: str = "",
    roadmap_id: str = "",
    reason: str = "",
    mode: str = "",
) -> dict[str, Any]:
    """Unified create/edit workout planner with full context bundle + HITL pending action."""
    import json as _json
    import re
    import uuid as _uuid

    from app.config import ModelTier
    from app.models.router import _build_chat_client

    resolved_mode = (mode or "").strip().lower()
    if not resolved_mode:
        resolved_mode = "edit" if (edit_intent or session_id) else "create"

    tz = resolve_tz_name(ctx)
    window = resolve_plan_window(
        horizon=horizon,
        days=days,
        from_date=from_date,
        to_date=to_date,
        week_start_date=week_start_date,
        target_slots=target_slots,
        today=local_today(ctx),
    )
    bundle = await assemble_workout_plan_context(
        ctx, window=window, mode=resolved_mode, session_id=session_id,
    )
    _rid = roadmap_id or (bundle.get("roadmap") or {}).get("id") or ""
    if not _rid:
        return {
            "error": "Bạn chưa có lộ trình active. Hãy tạo lộ trình trước khi lên lịch tập.",
            "hint": "create_roadmap",
        }
    allows_ai = _roadmap_allows_ai_reschedule(bundle.get("roadmap") or {})
    recovery = bundle.get("recovery") or {}
    fatigue = recovery.get("fatigueLevel") or 3
    try:
        fatigue_n = float(fatigue)
    except (TypeError, ValueError):
        fatigue_n = 3.0
    spd = max(1, min(int(sessions_per_day or 1), 3))
    suggested = _suggested_session_count(window, spd)
    if fatigue_n >= 7:
        suggested = max(2, suggested - 1)

    prompt_system = (
        "Bạn là AI Coach thiết kế/chỉnh lịch tập dựa trên dữ liệu THẬT từ tool. "
        "Cơ sở bắt buộc: (1) mục tiêu+phase roadmap, (2) sinh trắc+target, (3) phục hồi, "
        "(4) execution logs CHI TIẾT 7 ngày gần nhất kèm set logs, (5) injuries/medications. "
        "Progressive overload dựa trên set logs; nếu fatigue/recovery xấu → deload, không tăng tải. "
        "Tôn trọng chấn thương/thuốc. KHÔNG bịa số liệu. CHỈ trả JSON, không markdown.\n"
        "NHIỀU BUỔI CÙNG NGÀY (vd '2 buổi mỗi ngày'): mỗi buổi PHẢI một khung giờ khác nhau "
        "(vd sáng 06:30 và tối 19:30 — tôn trọng giờ user thích cho buổi chính) và cường độ/"
        "loại KHÁC nhau: 1 buổi chính (Strength, nặng hơn) + 1 buổi phụ nhẹ (Cardio/Mobility/Core, "
        "ngắn hơn, energyDemand thấp) để tránh quá tải; tiêu đề phân biệt rõ (vd '… (Sáng)'/'… (Tối)').\n"
        "PHỦ ĐỦ NGÀY: sessions_per_day=k>1 → tạo ĐÚNG k buổi cho MỖI ngày từ from_date đến "
        "to_date, không bỏ ngày nào (trừ khi recovery kém — phải nói rõ trong summary). "
        "KHÔNG tạo buổi ngoài khoảng from_date→to_date.\n"
        "summary KHÔNG ghi thứ trong tuần (Thứ Hai/Ba/…) — chỉ ngày dd/mm và giờ; "
        "model không được tự suy thứ từ ngày (dễ sai).\n"
        "CREATE → JSON array sessions: "
        "{date,time,sessionTitle,sessionType,estimatedDurationMinutes,"
        "executionBlocks:[{order,exerciseName,targetSets,targetReps,targetWeightKg,restSeconds,tempo}]}. "
        "EDIT → JSON object: {summary, diff:{add:[...sessions], update:[{sessionId,sessionTitle,sessionType,"
        "estimatedDurationMinutes,executionBlocks:[...]}], "
        "reschedule:[{sessionId,newDate,newTime}], remove:[sessionId]}}. "
        "summary phải là câu tiếng Việt thân thiện (không JSON, không tên field kỹ thuật)."
    )
    prompt_user = (
        f"mode={resolved_mode}\n"
        f"window={_json.dumps(window, ensure_ascii=False)}\n"
        f"edit_intent={edit_intent or '(create)'}\n"
        f"session_id={session_id or ''}\n"
        f"reason={reason or ''}\n"
        f"sessions_per_day={spd}\n"
        f"suggested_sessions≈{suggested}\n"
        f"context_bundle={_json.dumps(bundle, ensure_ascii=False, default=str)}\n"
    )

    raw_text = ""
    try:
        # Non-streaming + empty callbacks: nested planner JSON must not leak into chat SSE.
        model = _build_chat_client(ModelTier.LARGE, streaming=False)
        response = await model.ainvoke(
            [
                {"role": "system", "content": prompt_system},
                {"role": "user", "content": prompt_user},
            ],
            config={"callbacks": [], "tags": ["internal_planner"]},
        )
        raw_text = response.content if hasattr(response, "content") else str(response)
    except Exception as exc:
        return {"error": f"Không thể tạo/chỉnh lịch tập: {exc}"}

    parsed: Any = None
    try:
        parsed = _json.loads(raw_text)
    except Exception:
        m_obj = re.search(r"\{.*\}", raw_text, re.DOTALL)
        m_arr = re.search(r"\[.*\]", raw_text, re.DOTALL)
        try:
            if resolved_mode == "edit" and m_obj:
                parsed = _json.loads(m_obj.group())
            elif m_arr:
                parsed = _json.loads(m_arr.group())
            elif m_obj:
                parsed = _json.loads(m_obj.group())
        except Exception:
            parsed = None

    if parsed is None:
        return {"error": "LLM không trả về JSON lịch tập hợp lệ."}

    default_duration = int(recovery.get("recommendedWorkoutDuration") or 45)
    action_id = str(_uuid.uuid4())

    if resolved_mode == "edit":
        diff = parsed.get("diff") if isinstance(parsed, dict) else {}
        if not isinstance(diff, dict):
            diff = {}
        add_sessions = await resolve_exercise_ids(ctx.user_id, list(diff.get("add") or []))
        update_sessions = await resolve_exercise_ids(ctx.user_id, list(diff.get("update") or []))
        # re-attach sessionId after resolve
        for src, dst in zip(diff.get("update") or [], update_sessions):
            if isinstance(src, dict) and src.get("sessionId"):
                dst["sessionId"] = src["sessionId"]
        intent_text = " ".join(x for x in (edit_intent, reason) if x).strip()
        add_sessions = apply_explicit_edit_overrides(add_sessions, intent_text)
        update_sessions = apply_explicit_edit_overrides(update_sessions, intent_text)
        add_sessions = _spread_session_times(add_sessions)

        substitute_meta: dict[str, Any] = {}
        pair = parse_substitute_intent(intent_text)
        if pair:
            from_name, to_name = pair
            existing = bundle.get("existing_sessions") or bundle.get("sessions") or []
            if not isinstance(existing, list):
                existing = []
            update_sessions, substitute_meta = await apply_force_substitute(
                ctx.user_id,
                update_sessions=update_sessions,
                existing_sessions=existing,
                from_name=from_name,
                to_name=to_name,
                edit_intent=intent_text,
            )
            # Title regen for any update without force path title
            for u in update_sessions:
                if isinstance(u, dict) and u.get("executionBlocks") and not pair:
                    u["sessionTitle"] = regen_session_title(
                        list(u.get("executionBlocks") or []), hint=intent_text,
                    )

        if substitute_meta.get("savable") is False:
            tip = substitute_meta.get("message") or ""
            return {
                "status": "suggestion_only",
                "savable": False,
                "summary": tip,
                "message": tip,
                "suggestion": substitute_meta.get("suggestion"),
                "note": "Bài thay thế ngoài thư viện — không tạo pending ghi DB.",
            }

        ops = {
            "add": _sessions_to_schedule_payload(
                ctx.user_id, str(_rid), add_sessions, default_duration, timezone_id=tz,
            ),
            "update": update_sessions,
            "reschedule": [x for x in (diff.get("reschedule") or []) if isinstance(x, dict)],
            "remove": [str(x) for x in (diff.get("remove") or [])],
        }
        # If we forced substitute via update blocks, drop naked remove that only deleted A
        # (blocks already replaced A→B inside update).
        if pair and update_sessions:
            ops["remove"] = []

        llm_summary = parsed.get("summary") if isinstance(parsed, dict) else ""
        prose_sessions = update_sessions + add_sessions
        summary = format_sessions_prose(
            prose_sessions,
            window=window,
            reason=str(llm_summary or "").strip()
            or f"Đã chỉnh theo yêu cầu: {intent_text or 'cập nhật lịch'}.",
            ask_confirm=False,
        )
        staged = {
            "mode": "edit",
            "roadmap_id": _rid,
            "ops": ops,
        }
        ctx.display_payload.append({
            "type": "workout_plan_preview",
            "mode": "edit",
            "diff": ops,
            "summary": summary,
        })
        if not allows_ai:
            pending = _enable_ai_reschedule_pending(
                action_id=action_id,
                roadmap_id=str(_rid),
                summary=summary,
                staged=staged,
            )
            ctx.pending_actions.append(pending)
            return {
                "status": "pending_confirmation",
                "action_id": action_id,
                "message": (
                    f"{summary}\n\n"
                    "Lộ trình chưa cho phép AI chỉnh lịch. "
                    "Bấm xác nhận để bật quyền và lưu thay đổi."
                ),
                "mode": "edit",
                "needs_allow_ai_reschedule": True,
            }
        pending = _plan_or_edit_workout_pending(
            action_id=action_id,
            roadmap_id=str(_rid),
            summary=summary,
            staged=staged,
        )
        ctx.pending_actions.append(pending)
        return {
            "status": "pending_confirmation",
            "action_id": action_id,
            "message": f"{summary}\n\nBấm xác nhận để lưu thay đổi vào lịch tập.",
            "mode": "edit",
        }

    # create mode
    sessions_json = parsed if isinstance(parsed, list) else (parsed.get("sessions") if isinstance(parsed, dict) else [])
    if not isinstance(sessions_json, list) or not sessions_json:
        return {"error": "LLM không trả về danh sách buổi tập."}

    # If slots specified, pin dates/times onto generated sessions in order
    slots = window.get("slots") or []
    if slots:
        for i, slot in enumerate(slots):
            if i < len(sessions_json) and isinstance(sessions_json[i], dict):
                sessions_json[i]["date"] = slot["date"]
                sessions_json[i]["time"] = slot["time"]

    resolved = await resolve_exercise_ids(ctx.user_id, [s for s in sessions_json if isinstance(s, dict)])
    unresolved_names = list(getattr(resolve_exercise_ids, "last_unresolved", []) or [])
    # Strip internal meta before schedule payload
    for s in resolved:
        s.pop("_unresolved_exercises", None)
        s.pop("_all_unresolved_exercises", None)
    resolved = _spread_session_times(resolved)
    week_sessions = _sessions_to_schedule_payload(
        ctx.user_id, str(_rid), resolved, default_duration, timezone_id=tz,
    )
    if not week_sessions:
        detail = ""
        if unresolved_names:
            sample = ", ".join(unresolved_names[:8])
            more = f" (+{len(unresolved_names) - 8})" if len(unresolved_names) > 8 else ""
            detail = f" Không khớp catalog: {sample}{more}."
        return {
            "error": (
                "Không resolve được bài tập từ catalog (exerciseId)."
                f"{detail} Thử lại với tên bài tiếng Anh phổ biến (Squat, Bench Press…)."
            ),
        }
    note_partial = ""
    if unresolved_names:
        sample = ", ".join(unresolved_names[:5])
        note_partial = (
            f"\n\n(Đã bỏ qua {len(unresolved_names)} bài không có trong thư viện: {sample}.)"
        )

    snap = ctx.state.get("user_snapshot") or {}
    goal = snap.get("fitnessGoal") or ""
    reason_bits = []
    if goal:
        reason_bits.append(f"Bám mục tiêu {goal}")
    if reason:
        reason_bits.append(reason.strip())
    phase = (bundle.get("roadmap") or {}).get("currentPhase") or ""
    if phase:
        reason_bits.append(f"phase {phase}")
    why = ". ".join(reason_bits)
    if why:
        why = why[0].upper() + why[1:] + "."

    summary = format_sessions_prose(resolved, window=window, reason=why, ask_confirm=False)
    if note_partial:
        summary = f"{summary}{note_partial}"
    staged = {
        "mode": "create",
        "roadmap_id": _rid,
        "sessions": week_sessions,
    }
    ctx.display_payload.append({
        "type": "workout_plan_preview",
        "mode": "create",
        "sessions": resolved,
    })

    if not allows_ai:
        pending = _enable_ai_reschedule_pending(
            action_id=action_id,
            roadmap_id=str(_rid),
            summary=summary,
            staged=staged,
        )
        ctx.pending_actions.append(pending)
        return {
            "status": "pending_confirmation",
            "action_id": action_id,
            "message": (
                f"{summary}\n\n"
                "Lộ trình chưa cho phép AI chỉnh lịch. "
                "Bấm xác nhận để bật quyền và lưu lịch này."
            ),
            "sessions_count": len(week_sessions),
            "mode": "create",
            "needs_allow_ai_reschedule": True,
        }

    pending = _plan_or_edit_workout_pending(
        action_id=action_id,
        roadmap_id=str(_rid),
        summary=summary,
        staged=staged,
    )
    ctx.pending_actions.append(pending)
    return {
        "status": "pending_confirmation",
        "action_id": action_id,
        "message": f"{summary}\n\nBấm xác nhận để lưu lịch tập vào lộ trình.",
        "sessions_count": len(week_sessions),
        "mode": "create",
    }


async def generate_week_plan(
    ctx: ToolRunContext,
    roadmap_id: str = "",
    week_start_date: str = "",
    reason: str = "",
) -> dict[str, Any]:
    """Alias → plan_or_edit_workout(horizon=week, mode=create)."""
    return await plan_or_edit_workout(
        ctx,
        horizon="week",
        week_start_date=week_start_date,
        roadmap_id=roadmap_id,
        reason=reason,
        mode="create",
    )


def _num(v: Any, default: float = 0.0) -> float:
    try:
        if v is None:
            return default
        return float(v)
    except (TypeError, ValueError):
        return default


async def evaluate_food_fit(
    ctx: ToolRunContext,
    food_menu_item_id: str = "",
    days: int = 7,
) -> dict[str, Any]:
    """Compare dish macros vs targets + recent meal logs; no invented numbers."""
    fid = (food_menu_item_id or "").strip()
    if not fid:
        return {"error": "Thiếu food_menu_item_id (dùng foodId từ dish_list)."}

    food = await dotnet.get_food_detail(ctx.user_id, fid)
    if not isinstance(food, dict) or food.get("error"):
        return {
            "error": "Không tìm thấy món.",
            "food_menu_item_id": fid,
            "detail": food if isinstance(food, dict) else {},
        }
    if not (food.get("id") or food.get("Id") or food.get("nameVi") or food.get("NameVi")):
        return {"error": "Không tìm thấy món.", "food_menu_item_id": fid}

    name = str(food.get("nameVi") or food.get("NameVi") or food.get("name") or "Món")
    cal = _num(food.get("calories") or food.get("Calories"))
    protein = _num(food.get("proteinG") or food.get("ProteinG") or food.get("protein"))
    carbs = _num(food.get("carbG") or food.get("CarbG") or food.get("carbohydrate") or food.get("carbs"))
    fat = _num(food.get("fatG") or food.get("FatG") or food.get("fat"))

    snap = ctx.state.get("user_snapshot") or {}
    targets = await dotnet.get_nutrition_targets(ctx.user_id)
    if not isinstance(targets, dict):
        targets = {}
    t_cal = _num(
        targets.get("dailyCalorieTarget")
        or targets.get("DailyCalorieTarget")
        or snap.get("baseTDEE")
        or snap.get("tdee"),
        2000,
    )
    t_p = _num(targets.get("proteinG") or targets.get("ProteinG") or snap.get("proteinTargetG"))
    t_c = _num(targets.get("carbG") or targets.get("CarbG") or snap.get("carbTargetG"))
    t_f = _num(targets.get("fatG") or targets.get("FatG") or snap.get("fatTargetG"))
    goal = str(
        snap.get("fitnessGoal") or targets.get("fitnessGoal") or targets.get("goal") or ""
    )

    from app.tools.time_utils import local_today, resolve_tz_name

    tz = resolve_tz_name(ctx)
    today = local_today(ctx)
    n_days = max(1, min(int(days or 7), 14))
    day_summaries: list[dict[str, Any]] = []
    sum_cal = sum_p = sum_c = sum_f = 0.0
    for i in range(n_days):
        d = (today - timedelta(days=i)).isoformat()
        try:
            s = await dotnet.get_daily_summary(ctx.user_id, date=d, time_zone_id=tz)
        except Exception:
            s = {}
        if not isinstance(s, dict):
            s = {}
        dc = _num(s.get("totalCalories") or s.get("TotalCalories") or s.get("calories"))
        dp = _num(s.get("totalProteinG") or s.get("TotalProteinG") or s.get("proteinG"))
        dcarb = _num(s.get("totalCarbG") or s.get("TotalCarbG") or s.get("carbG"))
        df = _num(s.get("totalFatG") or s.get("TotalFatG") or s.get("fatG"))
        sum_cal += dc
        sum_p += dp
        sum_c += dcarb
        sum_f += df
        day_summaries.append({
            "date": d, "calories": dc, "proteinG": dp, "carbG": dcarb, "fatG": df,
        })

    avg_cal = sum_cal / n_days
    today_s = day_summaries[0] if day_summaries else {}
    remain_cal = max(0.0, t_cal - _num(today_s.get("calories")))
    remain_p = max(0.0, t_p - _num(today_s.get("proteinG"))) if t_p else None
    remain_c = max(0.0, t_c - _num(today_s.get("carbG"))) if t_c else None
    remain_f = max(0.0, t_f - _num(today_s.get("fatG"))) if t_f else None

    reasons: list[str] = []
    score = 0
    # Calorie fit for today
    if cal <= 0:
        reasons.append("Món chưa có số calo trong catalog — không thể đánh giá đầy đủ.")
    elif cal <= remain_cal + 50:
        score += 2
        reasons.append(
            f"Calo món ~{cal:.0f}kcal, còn lại hôm nay ~{remain_cal:.0f}/{t_cal:.0f}kcal."
        )
    elif cal <= remain_cal + 200:
        score += 1
        reasons.append(
            f"Calo món ~{cal:.0f}kcal hơi sát/vượt phần còn lại hôm nay (~{remain_cal:.0f}kcal)."
        )
    else:
        score -= 1
        reasons.append(
            f"Calo món ~{cal:.0f}kcal cao so với phần còn lại hôm nay (~{remain_cal:.0f}/{t_cal:.0f})."
        )

    if t_p and protein:
        if protein >= min(20.0, remain_p or 20):
            score += 1
            reasons.append(f"Protein ~{protein:.0f}g hỗ trợ target ({t_p:.0f}g/ngày).")
        else:
            reasons.append(f"Protein món ~{protein:.0f}g (target ngày {t_p:.0f}g).")

    if t_c and carbs:
        high_carb_goal = "lose" in goal.lower() or "fat" in goal.lower() or "giảm" in goal.lower()
        if high_carb_goal and carbs > (t_c * 0.4):
            score -= 1
            reasons.append(
                f"Carb ~{carbs:.0f}g khá cao so với target giảm mỡ ({t_c:.0f}g/ngày)."
            )
        elif carbs <= (remain_c or t_c):
            score += 1
            reasons.append(f"Carb ~{carbs:.0f}g trong ngưỡng hợp lý.")

    if avg_cal > t_cal * 1.1:
        score -= 1
        reasons.append(
            f"{n_days} ngày gần đây trung bình ~{avg_cal:.0f}kcal (> target {t_cal:.0f})."
        )
    elif avg_cal > 0:
        reasons.append(f"{n_days} ngày gần đây trung bình ~{avg_cal:.0f}kcal (target {t_cal:.0f}).")

    allergies = [str(x).lower() for x in (snap.get("allergies") or [])]
    name_l = name.lower()
    for a in allergies:
        if a and a in name_l:
            score -= 3
            reasons.append(f"Trùng dị ứng đã khai: {a}.")

    if score >= 2:
        verdict = "fit"
        label = "Hợp với chế độ dinh dưỡng hiện tại"
    elif score >= 0:
        verdict = "borderline"
        label = "Tạm ổn nếu điều chỉnh phần còn lại trong ngày"
    else:
        verdict = "not_fit"
        label = "Chưa hợp với mục tiêu/dư địa calo-macro hôm nay"

    result = {
        "status": "ok",
        "verdict": verdict,
        "label": label,
        "food": {
            "foodId": str(food.get("id") or food.get("Id") or fid),
            "name": name,
            "calories": cal,
            "proteinG": protein,
            "carbG": carbs,
            "fatG": fat,
        },
        "targets": {
            "calories": t_cal,
            "proteinG": t_p,
            "carbG": t_c,
            "fatG": t_f,
            "goal": goal,
        },
        "today_remaining": {
            "calories": remain_cal,
            "proteinG": remain_p,
            "carbG": remain_c,
            "fatG": remain_f,
        },
        "window_days": n_days,
        "avg_intake_calories": round(avg_cal, 1),
        "reasons": reasons,
        "message": f"{label}. " + " ".join(reasons[:3]),
    }
    ctx.display_payload.append({
        "type": "food_detail",
        "data": {
            **food,
            "foodId": result["food"]["foodId"],
            "fitVerdict": verdict,
            "fitLabel": label,
            "fitReasons": reasons,
        },
    })
    return result


async def suggest_meal_plan(
    ctx: ToolRunContext,
    target_calories: int | None = None,
    meals_per_day: int = 3,
) -> dict[str, Any]:
    snapshot = ctx.state.get("user_snapshot") or {}
    targets = await dotnet.get_nutrition_targets(ctx.user_id)
    cal = target_calories or targets.get("dailyCalorieTarget") or snapshot.get("baseTDEE") or 2000
    foods = await dotnet.search_food(ctx.user_id, query="protein", limit=5)
    plan = {
        "targetCalories": cal,
        "mealsPerDay": meals_per_day,
        "suggestedFoods": foods.get("items", foods),
    }
    ctx.display_payload.append({"type": "meal_plan", "data": plan})
    return plan


async def estimate_meal_from_photo(ctx: ToolRunContext, image_url: str) -> dict[str, Any]:
    if not get_settings().vision_enabled:
        return {"error": "vision_disabled", "hint": "Bật VISION_ENABLED để dùng nhận diện ảnh."}
    return {
        "imageUrl": image_url,
        "note": "Vision chưa cấu hình model — dùng search_food hoặc log_meal thủ công.",
        "suggestedAction": "search_food",
    }
