"""Insight stats tools — nutrition/workout/body charts + predictions (Premium)."""
from __future__ import annotations

import math
import uuid
from datetime import date, timedelta
from typing import Any

from app.graph.subscription_gating import insight_premium_allowed, normalize_tier
from app.tools import dotnet
from app.tools.context import ToolRunContext
from app.tools.insight_charts import (
    band_annotation,
    chart_payload,
    insight_dashboard,
    premium_upsell_payload,
    projection_annotation,
    series,
    target_line,
)
from app.tools.time_utils import local_today, resolve_tz_name

_KCAL_PER_KG = 7700.0
_MAX_PERIOD_DAYS = 366


def _tier(ctx: ToolRunContext) -> str:
    snap = ctx.state.get("user_snapshot") or {}
    return normalize_tier(
        ctx.state.get("subscription_tier")
        or snap.get("subscriptionTier")
        or snap.get("SubscriptionTier")
    )


def _premium_block(ctx: ToolRunContext, *, feature: str = "AI Insights & biểu đồ") -> dict[str, Any]:
    """Server-side gate: Free cannot see advanced stats/charts."""
    action_id = str(uuid.uuid4())
    is_android = str(ctx.state.get("client_platform") or "").lower() == "android"
    payload = premium_upsell_payload(feature=feature)
    if is_android:
        payload = {**payload, "cta": "play_billing", "route": "/subscription"}
    ctx.display_payload.append(payload)
    ctx.pending_actions.append({
        "action_id": action_id,
        "type": "upgrade_premium",
        "plan_hint": "Premium",
        "summary": "Nâng Premium để mở AI Insights, biểu đồ và dự đoán mục tiêu.",
        "status": "awaiting_confirmation",
        "feature": feature,
        "client_platform": ctx.state.get("client_platform") or "unknown",
    })
    msg = (
        "Tính năng thống kê đa kỳ + biểu đồ + dự đoán dành cho Premium. "
        + (
            "Trên Android hãy mở Gói đăng ký và mua qua Google Play."
            if is_android
            else "Bạn có muốn nâng cấp không? Bấm xác nhận để nhận mã VietQR."
        )
    )
    return {
        "status": "premium_required",
        "message": msg,
        "action_id": action_id,
        "charts": [],
    }


def parse_period(
    period: str | int | None = None,
    *,
    today: date | None = None,
) -> tuple[date, date, int, str]:
    """Return (from_date, to_date, day_count, label). Defaults to 14 days."""
    today = today or date.today()
    raw = str(period or "14d").strip().lower()
    days = 14
    label = "14 ngày"

    import re
    m = re.match(r"^(\d+)\s*(d|day|days|ngày|ngay)?$", raw)
    if m and (m.group(2) or raw.isdigit()):
        days = int(m.group(1))
        label = f"{days} ngày"
    else:
        m = re.match(r"^(\d+)\s*(w|week|weeks|tuần|tuan)$", raw)
        if m:
            days = int(m.group(1)) * 7
            label = f"{m.group(1)} tuần"
        else:
            m = re.match(r"^(\d+)\s*(m|mo|month|months|tháng|thang)$", raw)
            if m:
                days = int(m.group(1)) * 30
                label = f"{m.group(1)} tháng"
            elif raw in ("week", "1w", "tuần"):
                days, label = 7, "1 tuần"
            elif raw in ("month", "1m", "tháng"):
                days, label = 30, "1 tháng"
            elif raw in ("8w", "8 tuần", "8 tuan"):
                days, label = 56, "8 tuần"

    days = max(3, min(days, _MAX_PERIOD_DAYS))
    from_d = today - timedelta(days=days - 1)
    return from_d, today, days, label


def _bucket_key(d: date, granularity: str) -> str:
    g = (granularity or "day").lower()
    if g == "month":
        return f"{d.year}-{d.month:02d}"
    if g == "week":
        iso = d.isocalendar()
        return f"{iso.year}-W{iso.week:02d}"
    return d.isoformat()


def _bucket_label(key: str, granularity: str) -> str:
    g = (granularity or "day").lower()
    if g == "month":
        return key  # YYYY-MM
    if g == "week":
        return key.replace("-W", " T")
    # day → short MM-DD
    try:
        return key[5:]
    except Exception:
        return key


def _avg(vals: list[float]) -> float | None:
    return sum(vals) / len(vals) if vals else None


def _confidence(*, logged_ratio: float, workout_count: int, days: int) -> str:
    if logged_ratio >= 0.7 and workout_count >= max(4, days // 7):
        return "cao"
    if logged_ratio >= 0.45 and workout_count >= 2:
        return "trung bình"
    return "thấp"


# Vùng calo khuyến nghị theo mục tiêu, quanh target chuẩn (maintenance từ IAM).
# Giảm mỡ → khuyến khích thâm hụt 200-400 (vùng chấp nhận rộng hơn 100-500);
# tăng cơ → thặng dư nhẹ; duy trì → ±10%. Dùng chung cho adherence + đường mục tiêu.
_DEFICIT_ENCOURAGED = 300.0
_DEFICIT_BAND = (100.0, 500.0)
_SURPLUS_ENCOURAGED = 250.0
_SURPLUS_BAND = (100.0, 500.0)


def _goal_kind(goal: str | None) -> str:
    g = str(goal or "").lower()
    if any(k in g for k in ("lose", "fat", "giảm", "giam", "cut")):
        return "deficit"
    if any(k in g for k in ("gain", "muscle", "tăng", "tang", "bulk")):
        return "surplus"
    return "maintain"


def _goal_calorie_band(goal: str | None, target: float, *, engine_managed: bool = False) -> dict[str, Any]:
    """(encouraged, band_min, band_max, label, kind) cho 1 mức target chuẩn.

    engine_managed=True nghĩa là target ĐÃ là mục tiêu goal-adjusted do Adaptive
    Engine tính (đã gồm deficit/surplus) → tuân thủ đo ±10% quanh nó, KHÔNG trừ
    thêm deficit lần nữa (tránh double-count).
    """
    kind = _goal_kind(goal)
    if target <= 0:
        return {"encouraged": target, "band_min": 0.0, "band_max": 0.0, "label": "", "kind": kind}
    if engine_managed:
        return {
            "encouraged": target,
            "band_min": target * 0.9,
            "band_max": target * 1.1,
            "label": "±10% quanh mục tiêu Adaptive Engine",
            "kind": kind,
        }
    if kind == "deficit":
        return {
            "encouraged": target - _DEFICIT_ENCOURAGED,
            "band_min": target - _DEFICIT_BAND[1],
            "band_max": target - _DEFICIT_BAND[0],
            "label": "thâm hụt 100-500 kcal (khuyến nghị 200-400)",
            "kind": kind,
        }
    if kind == "surplus":
        return {
            "encouraged": target + _SURPLUS_ENCOURAGED,
            "band_min": target + _SURPLUS_BAND[0],
            "band_max": target + _SURPLUS_BAND[1],
            "label": "thặng dư 100-500 kcal",
            "kind": kind,
        }
    return {
        "encouraged": target,
        "band_min": target * 0.9,
        "band_max": target * 1.1,
        "label": "±10% quanh mục tiêu",
        "kind": kind,
    }


def _snap_num(snap: dict[str, Any], *keys: str) -> float | None:
    for k in keys:
        v = snap.get(k)
        if v is not None:
            try:
                return float(v)
            except (TypeError, ValueError):
                pass
    return None


def _unwrap_items(result: Any) -> list[Any]:
    if isinstance(result, list):
        return result
    if not isinstance(result, dict):
        return []
    for k in ("items", "Items", "buckets", "Buckets", "data", "Data", "points", "Points"):
        v = result.get(k)
        if isinstance(v, list):
            return v
    return []


async def get_nutrition_stats(
    ctx: ToolRunContext,
    period: str = "14d",
    granularity: str = "day",
    *,
    emit_charts: bool = True,
    **_: Any,
) -> dict[str, Any]:
    if not insight_premium_allowed(_tier(ctx)):
        return _premium_block(ctx)

    today = local_today(ctx)
    from_d, to_d, days, label = parse_period(period, today=today)
    gran = (granularity or "day").lower()
    if gran not in ("day", "week", "month"):
        gran = "day"

    raw = await dotnet.get_nutrition_timeseries(
        ctx.user_id,
        from_date=from_d.isoformat(),
        to_date=to_d.isoformat(),
        granularity=gran,
    )
    buckets = _unwrap_items(raw)
    if not buckets and isinstance(raw, dict) and raw.get("error"):
        return {"status": "error", "message": str(raw.get("error")), "charts": []}

    snap = ctx.state.get("user_snapshot") or {}
    goal = str(snap.get("fitnessGoal") or snap.get("FitnessGoal") or "")
    goal_kind = _goal_kind(goal)
    engine_managed = bool(snap.get("targetsManagedByEngine") or snap.get("TargetsManagedByEngine"))

    x_labels: list[str] = []
    cal_in: list[float | None] = []
    cal_tgt: list[float | None] = []
    protein: list[float | None] = []
    carb: list[float | None] = []
    fat: list[float | None] = []
    water: list[float | None] = []
    adherence: list[float | None] = []
    encouraged_tgt: list[float | None] = []
    meals: list[float] = []

    logged_days = 0
    for b in buckets:
        if not isinstance(b, dict):
            continue
        key = str(b.get("key") or b.get("Key") or b.get("date") or b.get("Date") or "")
        x_labels.append(_bucket_label(key, gran) if key else "?")
        cin = b.get("consumedCalories", b.get("ConsumedCalories"))
        ctg = b.get("targetCalories", b.get("TargetCalories"))
        p = b.get("consumedProteinGram", b.get("ConsumedProteinGram"))
        c = b.get("consumedCarbGram", b.get("ConsumedCarbGram"))
        f = b.get("consumedFatGram", b.get("ConsumedFatGram"))
        w = b.get("waterIntakeMl", b.get("WaterIntakeMl"))
        ml = int(b.get("mealsLoggedCount", b.get("MealsLoggedCount") or 0) or 0)
        meals.append(float(ml))
        if ml > 0 or (cin is not None and float(cin or 0) > 0):
            logged_days += 1

        def _f(v: Any) -> float | None:
            if v is None:
                return None
            try:
                return float(v)
            except (TypeError, ValueError):
                return None

        cal_in.append(_f(cin))
        cal_tgt.append(_f(ctg))
        protein.append(_f(p))
        carb.append(_f(c))
        fat.append(_f(f))
        water.append(_f(w))
        # Tuân thủ = ngày calo nạp nằm trong VÙNG hợp mục tiêu (giảm mỡ → vùng thâm
        # hụt, không phải ±10% quanh maintenance — nếu không luôn ra 0%).
        if cin is not None and ctg and float(ctg) > 0:
            band = _goal_calorie_band(goal, float(ctg), engine_managed=engine_managed)
            encouraged_tgt.append(band["encouraged"])
            in_band = band["band_min"] <= float(cin) <= band["band_max"]
            adherence.append(100.0 if in_band else 0.0)
        else:
            encouraged_tgt.append(None)
            adherence.append(None)

    if not x_labels:
        return {
            "status": "insufficient_data",
            "message": f"Chưa có dữ liệu dinh dưỡng trong {label}. Hãy log bữa ăn thêm rồi hỏi lại.",
            "charts": [],
            "period": label,
            "confidence": "thấp",
            "factors": [],
        }

    avg_cal = _avg([v for v in cal_in if v is not None])
    avg_tgt = _avg([v for v in cal_tgt if v is not None])
    adh_vals = [v for v in adherence if v is not None]
    adh_pct = (_avg(adh_vals) or 0) if adh_vals else 0
    logged_ratio = logged_days / max(1, len(x_labels))

    charts: list[dict[str, Any]] = []
    avg_encouraged = _avg([v for v in encouraged_tgt if v is not None])
    band_desc = (
        _goal_calorie_band(goal, avg_tgt or 0, engine_managed=engine_managed).get("label")
        if avg_tgt else ""
    )

    cal_series = [
        series("Đã nạp", cal_in),
        series("Mục tiêu chuẩn", cal_tgt, style="dashed"),
    ]
    cal_ann: list[dict[str, Any]] = [target_line(avg_tgt)] if avg_tgt else []
    # Giảm mỡ/tăng cơ: thêm đường "mục tiêu khuyến nghị" (thâm hụt/thặng dư) để
    # user thấy mức nên nhắm tới, không chỉ mức maintenance.
    # Engine-managed: target ĐÃ là mục tiêu khuyến nghị → không vẽ đường trùng.
    if goal_kind != "maintain" and not engine_managed and any(v is not None for v in encouraged_tgt):
        enc_label = "Mục tiêu khuyến nghị (thâm hụt)" if goal_kind == "deficit" else "Mục tiêu khuyến nghị (thặng dư)"
        cal_series.append(series(enc_label, encouraged_tgt, style="dashed"))
        if avg_encouraged is not None:
            cal_ann.append(target_line(avg_encouraged, label=enc_label))
    cal_subtitle = "Đã nạp vs mục tiêu chuẩn" + (f" · khuyến nghị {band_desc}" if band_desc and goal_kind != "maintain" else "")
    charts.append(chart_payload(
        chart_type="line",
        title=f"Calo nạp — {label}",
        subtitle=cal_subtitle,
        unit="kcal",
        granularity=gran,
        x_labels=x_labels,
        series=cal_series,
        annotations=cal_ann,
        summary=(
            f"Trung bình {avg_cal:,.0f} kcal/ngày" if avg_cal is not None else "Thiếu dữ liệu calo"
        ) + (
            f"; khuyến nghị nhắm ~{avg_encouraged:,.0f} kcal ({band_desc})."
            if avg_encouraged is not None and goal_kind != "maintain" else ""
        ),
    ))
    charts.append(chart_payload(
        chart_type="stackedBar",
        title=f"Macro P/C/F — {label}",
        unit="g",
        granularity=gran,
        x_labels=x_labels,
        series=[
            series("Protein", protein),
            series("Carb", carb),
            series("Fat", fat),
        ],
        summary="Phân bổ macro theo kỳ.",
    ))
    charts.append(chart_payload(
        chart_type="area",
        title=f"Nước uống — {label}",
        unit="ml",
        granularity=gran,
        x_labels=x_labels,
        series=[series("Nước", water)],
        summary="Hydrat hoá theo kỳ.",
    ))
    # Chỉ vẽ biểu đồ tuân thủ khi có ngày đo được (tránh cột 0% vô nghĩa).
    if adh_vals:
        adh_title = {
            "deficit": f"Tuân thủ vùng thâm hụt — {label}",
            "surplus": f"Tuân thủ vùng thặng dư — {label}",
        }.get(goal_kind, f"Tuân thủ calo (±10%) — {label}")
        charts.append(chart_payload(
            chart_type="bar",
            title=adh_title,
            subtitle=(f"Ngày đạt = calo trong vùng {band_desc}" if band_desc else "Ngày đạt mục tiêu"),
            unit="%",
            granularity=gran,
            x_labels=x_labels,
            series=[series("% ngày đạt", adherence)],
            summary=f"Tỉ lệ ngày calo nằm trong vùng khuyến nghị khoảng {adh_pct:.0f}%.",
        ))

    for ch in charts:
        if emit_charts:
            ctx.display_payload.append(ch)

    factors = [
        f"{logged_days}/{len(x_labels)} bucket có log bữa",
        f"tuân thủ calo ~{adh_pct:.0f}%",
    ]
    if avg_cal is not None and avg_tgt:
        factors.append(f"calo TB {avg_cal:,.0f} vs mục tiêu {avg_tgt:,.0f}")

    conf = _confidence(logged_ratio=logged_ratio, workout_count=0, days=days)
    return {
        "status": "ok",
        "period": label,
        "granularity": gran,
        "charts_emitted": len(charts),
        "averageCalories": avg_cal,
        "averageTarget": avg_tgt,
        "adherencePct": adh_pct,
        "loggedRatio": logged_ratio,
        "confidence": conf,
        "factors": factors,
        "summary": (
            f"Dinh dưỡng {label}: calo TB {avg_cal:,.0f} kcal" if avg_cal is not None
            else f"Dinh dưỡng {label}: dữ liệu còn mỏng"
        ) + f", tuân thủ ~{adh_pct:.0f}% (độ tin cậy: {conf}).",
        "disclaimer": "Số liệu từ DailyNutritionSummary; đây là ước lượng, không phải tư vấn y khoa.",
        "charts": charts,
    }


async def evaluate_nutrition_adequacy(
    ctx: ToolRunContext,
    period: str = "14d",
    *,
    emit_charts: bool = True,
    **_: Any,
) -> dict[str, Any]:
    if not insight_premium_allowed(_tier(ctx)):
        return _premium_block(ctx)

    today = local_today(ctx)
    from_d, to_d, days, label = parse_period(period, today=today)
    raw = await dotnet.get_nutrition_timeseries(
        ctx.user_id,
        from_date=from_d.isoformat(),
        to_date=to_d.isoformat(),
        granularity="day",
    )
    buckets = _unwrap_items(raw)
    snap = ctx.state.get("user_snapshot") or {}
    tdee = _snap_num(snap, "baseTDEE", "BaseTDEE", "tdee", "TDEE") or 0
    weight = _snap_num(snap, "currentWeightKg", "CurrentWeightKg") or 0
    goal = str(snap.get("fitnessGoal") or snap.get("FitnessGoal") or "").lower()
    sex = str(snap.get("sex") or snap.get("Sex") or snap.get("gender") or "").lower()

    cal_vals: list[float] = []
    prot_vals: list[float] = []
    logged = 0
    for b in buckets:
        if not isinstance(b, dict):
            continue
        cin = b.get("consumedCalories", b.get("ConsumedCalories"))
        ml = int(b.get("mealsLoggedCount", b.get("MealsLoggedCount") or 0) or 0)
        p = b.get("consumedProteinGram", b.get("ConsumedProteinGram"))
        if ml > 0 or (cin is not None and float(cin or 0) > 0):
            logged += 1
        if cin is not None:
            try:
                cal_vals.append(float(cin))
            except (TypeError, ValueError):
                pass
        if p is not None:
            try:
                prot_vals.append(float(p))
            except (TypeError, ValueError):
                pass

    ratio = logged / max(1, days)
    if ratio < 0.6:
        return {
            "status": "insufficient_data",
            "verdict": "thiếu dữ liệu",
            "confidence": "thấp",
            "message": (
                f"Mới log khoảng {logged}/{days} ngày trong {label} "
                f"(cần ≥60–70% ngày có meal log). Hãy log thêm để đánh giá chính xác."
            ),
            "factors": [f"meal log {logged}/{days} ngày"],
            "predictionsAllowed": False,
        }

    avg_cal = _avg(cal_vals) or 0
    avg_prot = _avg(prot_vals) or 0
    prot_per_kg = (avg_prot / weight) if weight > 0 else None

    issues: list[str] = []
    verdict = "ổn"
    if tdee > 0:
        deficit_pct = (tdee - avg_cal) / tdee * 100
        if "lose" in goal or "fat" in goal or "giảm" in goal:
            if deficit_pct > 25:
                issues.append(f"deficit ~{deficit_pct:.0f}% TDEE (>25%) — quá lớn")
                verdict = "cần điều chỉnh"
            elif deficit_pct < 5:
                issues.append(f"deficit chỉ ~{deficit_pct:.0f}% — có thể chậm giảm mỡ")
                if verdict == "ổn":
                    verdict = "cần theo dõi"
            else:
                issues.append(f"deficit hợp lý ~{deficit_pct:.0f}% TDEE")
        elif "gain" in goal or "muscle" in goal or "tăng" in goal:
            surplus_pct = (avg_cal - tdee) / tdee * 100
            if surplus_pct > 15:
                issues.append(f"surplus ~{surplus_pct:.0f}% — hơi lớn")
                verdict = "cần điều chỉnh"
            elif surplus_pct < 0:
                issues.append("đang deficit trong khi mục tiêu tăng cơ")
                verdict = "cần điều chỉnh"
            else:
                issues.append(f"surplus nhẹ ~{surplus_pct:.0f}%")
        else:
            if abs(avg_cal - tdee) / tdee > 0.05:
                issues.append(f"lệch TDEE {(avg_cal - tdee):+,.0f} kcal")
                verdict = "cần theo dõi"
            else:
                issues.append("quanh TDEE ±5%")

    floor = 1200 if sex in ("f", "female", "nữ", "nu") else 1500
    if avg_cal < floor:
        issues.append(f"calo TB {avg_cal:,.0f} < ngưỡng an toàn ~{floor}")
        verdict = "cần điều chỉnh"

    if prot_per_kg is not None and prot_per_kg < 1.6:
        issues.append(f"protein ~{prot_per_kg:.2f} g/kg (<1.6)")
        if verdict == "ổn":
            verdict = "cần theo dõi"

    conf = _confidence(logged_ratio=ratio, workout_count=0, days=days)
    factors = [
        f"{logged}/{days} ngày có meal log",
        f"calo TB {avg_cal:,.0f}",
    ]
    if tdee:
        factors.append(f"TDEE ~{tdee:,.0f}")
    if prot_per_kg is not None:
        factors.append(f"protein {prot_per_kg:.2f} g/kg")

    band_min = (tdee * 0.8) if tdee else avg_cal * 0.9
    band_max = (tdee * 0.95) if tdee else avg_cal * 1.1
    chart = chart_payload(
        chart_type="line",
        title=f"Đánh giá dinh dưỡng — {label}",
        subtitle="Calo nạp theo ngày",
        unit="kcal",
        granularity="day",
        x_labels=[str(b.get("date") or b.get("Date") or b.get("key") or "")[5:10]
                  if isinstance(b, dict) else "?" for b in buckets],
        series=[series("Đã nạp", [
            float(b.get("consumedCalories") or b.get("ConsumedCalories") or 0)
            if isinstance(b, dict) else 0
            for b in buckets
        ])],
        annotations=[
            *( [target_line(tdee, label="TDEE")] if tdee else [] ),
            band_annotation("vùng tham chiếu", band_min, band_max),
        ],
        summary=f"Verdict: {verdict}. " + "; ".join(issues),
    )
    if emit_charts:
        ctx.display_payload.append(chart)

    return {
        "status": "ok",
        "verdict": verdict,
        "confidence": conf,
        "period": label,
        "averageCalories": avg_cal,
        "tdee": tdee or None,
        "proteinPerKg": prot_per_kg,
        "issues": issues,
        "factors": factors,
        "charts": [chart],
        "message": (
            f"Dựa trên {logged} ngày có log trong {label}, calo TB {avg_cal:,.0f}"
            + (f" (TDEE ~{tdee:,.0f})" if tdee else "")
            + f" → nhận định: {verdict} (độ tin cậy: {conf}). "
            + " ".join(issues)
            + " Đây là ước lượng, không phải tư vấn y khoa."
        ),
        "disclaimer": "Ước lượng từ meal logs + TDEE hồ sơ; không thay thế chuyên gia.",
    }


async def get_workout_stats(
    ctx: ToolRunContext,
    period: str = "14d",
    granularity: str = "week",
    exercise_id: str = "",
    *,
    emit_charts: bool = True,
    **_: Any,
) -> dict[str, Any]:
    if not insight_premium_allowed(_tier(ctx)):
        return _premium_block(ctx)

    today = local_today(ctx)
    from_d, to_d, days, label = parse_period(period, today=today)
    gran = (granularity or "week").lower()
    if gran not in ("day", "week", "month"):
        gran = "week"

    raw = await dotnet.get_workout_timeseries(
        ctx.user_id,
        from_date=from_d.isoformat(),
        to_date=to_d.isoformat(),
        granularity=gran,
        time_zone_id=resolve_tz_name(ctx),
    )
    buckets = _unwrap_items(raw)
    x_labels: list[str] = []
    completion: list[float | None] = []
    sessions_done: list[float | None] = []
    sessions_plan: list[float | None] = []
    volume: list[float | None] = []
    calories: list[float | None] = []
    total_logged = 0

    for b in buckets:
        if not isinstance(b, dict):
            continue
        key = str(b.get("key") or b.get("Key") or "")
        x_labels.append(_bucket_label(key, gran) if key else "?")
        done = float(b.get("sessionsCompleted") or b.get("SessionsCompleted") or 0)
        planned = float(b.get("sessionsPlanned") or b.get("SessionsPlanned") or 0)
        rate = b.get("completionRate") or b.get("CompletionRate")
        vol = b.get("volume") or b.get("Volume") or b.get("totalVolume")
        cal = b.get("caloriesBurned") or b.get("CaloriesBurned")
        sessions_done.append(done)
        sessions_plan.append(planned)
        total_logged += int(done)
        try:
            completion.append(float(rate) if rate is not None else (100.0 * done / planned if planned else None))
        except (TypeError, ValueError):
            completion.append(None)
        try:
            volume.append(float(vol) if vol is not None else None)
        except (TypeError, ValueError):
            volume.append(None)
        try:
            calories.append(float(cal) if cal is not None else None)
        except (TypeError, ValueError):
            calories.append(None)

    if total_logged < 4 and days >= 14:
        return {
            "status": "insufficient_data",
            "message": (
                f"Chỉ có {total_logged} buổi tập có log trong {label} "
                "(cần ≥4 buổi). Hãy tập/log thêm để có biểu đồ đáng tin."
            ),
            "charts": [],
            "confidence": "thấp",
            "factors": [f"{total_logged} buổi có log"],
        }

    charts: list[dict[str, Any]] = []
    if x_labels:
        charts.append(chart_payload(
            chart_type="bar",
            title=f"Buổi tập — {label}",
            unit="buổi",
            granularity=gran,
            x_labels=x_labels,
            series=[
                series("Hoàn thành", sessions_done),
                series("Kế hoạch", sessions_plan, style="dashed"),
            ],
            summary=f"Tổng {total_logged} buổi có log.",
        ))
        charts.append(chart_payload(
            chart_type="line",
            title=f"Tỉ lệ hoàn thành — {label}",
            unit="%",
            granularity=gran,
            x_labels=x_labels,
            series=[series("Completion", completion)],
            summary="Completion rate theo kỳ.",
        ))
        charts.append(chart_payload(
            chart_type="bar",
            title=f"Khối lượng tập — {label}",
            unit="kg·reps",
            granularity=gran,
            x_labels=x_labels,
            series=[series("Volume", volume)],
            summary="Σ sets×reps×kg.",
        ))
        charts.append(chart_payload(
            chart_type="bar",
            title=f"Calo đốt — {label}",
            unit="kcal",
            granularity=gran,
            x_labels=x_labels,
            series=[series("Calo đốt", calories)],
            summary="Calo đốt từ WorkoutExecutionLog.",
        ))

    if exercise_id:
        prog = await dotnet.get_strength_progression(
            ctx.user_id,
            exercise_id=exercise_id,
            from_date=from_d.isoformat(),
            to_date=to_d.isoformat(),
        )
        pts = _unwrap_items(prog)
        if pts:
            charts.append(chart_payload(
                chart_type="line",
                title="Tiến bộ sức mạnh (PR)",
                unit="kg",
                granularity="day",
                x_labels=[str(p.get("date") or p.get("Date") or "")[5:10]
                          if isinstance(p, dict) else "?" for p in pts],
                series=[series("Kg", [
                    float(p.get("weightKg") or p.get("WeightKg") or 0)
                    if isinstance(p, dict) else 0
                    for p in pts
                ])],
                summary="Max weight theo ngày từ ExerciseSetLog.",
            ))

    for ch in charts:
        if emit_charts:
            ctx.display_payload.append(ch)

    conf = _confidence(
        logged_ratio=min(1.0, total_logged / max(4, days // 3)),
        workout_count=total_logged,
        days=days,
    )
    factors = [f"{total_logged} buổi có log trong {label}"]
    return {
        "status": "ok",
        "period": label,
        "charts_emitted": len(charts),
        "sessionsLogged": total_logged,
        "confidence": conf,
        "factors": factors,
        "summary": f"Tập luyện {label}: {total_logged} buổi (độ tin cậy: {conf}).",
        "disclaimer": "Số liệu từ WorkoutExecutionLog / ExerciseSetLog.",
        "charts": charts,
    }


async def get_body_progress(
    ctx: ToolRunContext,
    period: str = "8w",
    *,
    emit_charts: bool = True,
    **_: Any,
) -> dict[str, Any]:
    """Weight trend from BiometricHistory (IAM weight-history); energy-balance fallback."""
    if not insight_premium_allowed(_tier(ctx)):
        return _premium_block(ctx)

    today = local_today(ctx)
    from_d, to_d, days, label = parse_period(period, today=today)
    snap = ctx.state.get("user_snapshot") or {}
    weight = _snap_num(snap, "currentWeightKg", "CurrentWeightKg")
    target = _snap_num(snap, "targetWeightKg", "TargetWeightKg")
    tdee = _snap_num(snap, "baseTDEE", "BaseTDEE", "tdee") or 0
    bf = _snap_num(snap, "bodyFatPercent", "BodyFatPercent", "currentBodyFatPercent")

    # ── Real weigh-ins from IAM BiometricHistory ─────────────────────────────
    hist_raw = await dotnet.get_weight_history(
        ctx.user_id,
        from_iso=from_d.isoformat(),
        to_iso=(to_d + timedelta(days=1)).isoformat(),
    )
    weigh_pts: list[tuple[str, float]] = []
    for item in _unwrap_items(hist_raw):
        if not isinstance(item, dict):
            continue
        ts = str(item.get("recordedAtUtc") or item.get("RecordedAtUtc") or "")[:10]
        w = item.get("weightKg", item.get("WeightKg"))
        try:
            wv = float(w) if w is not None else 0.0
        except (TypeError, ValueError):
            continue
        if ts and wv > 0:
            weigh_pts.append((ts, wv))
    weigh_pts.sort(key=lambda p: p[0])

    if weigh_pts:
        x_labels = [p[0][5:] for p in weigh_pts]  # MM-DD
        series_w = [round(p[1], 2) for p in weigh_pts]
        latest = series_w[-1]
        first = series_w[0]
        span_days = max(1, (
            date.fromisoformat(weigh_pts[-1][0]) - date.fromisoformat(weigh_pts[0][0])
        ).days)
        kg_per_week = ((latest - first) / span_days) * 7 if span_days else 0.0
        ann = []
        if target:
            ann.append(target_line(target, label="Mục tiêu cân"))
        chart = chart_payload(
            chart_type="line",
            title=f"Cân nặng — {label}",
            subtitle=f"{len(weigh_pts)} lần cân từ BiometricHistory",
            unit="kg",
            granularity="day",
            x_labels=x_labels,
            series=[
                series("Cân đo", series_w),
                *([series("Mục tiêu", [target] * len(series_w), style="dashed")] if target else []),
            ],
            annotations=ann,
            summary=(
                f"{first:.1f} → {latest:.1f} kg (~{kg_per_week:+.2f} kg/tuần) "
                f"trên {span_days} ngày, {len(weigh_pts)} lần cân."
            ),
        )
        if emit_charts:
            ctx.display_payload.append(chart)
        factors = [
            f"{len(weigh_pts)} lần cân",
            f"{span_days} ngày cửa sổ",
            f"~{kg_per_week:+.2f} kg/tuần",
        ]
        if bf is not None:
            factors.append(f"% mỡ hiện tại {bf:.1f}%")
        conf = "cao" if len(weigh_pts) >= 6 else ("trung bình" if len(weigh_pts) >= 3 else "thấp")
        return {
            "status": "ok",
            "period": label,
            "currentWeightKg": latest,
            "targetWeightKg": target,
            "kgPerWeekEstimate": kg_per_week,
            "weighInCount": len(weigh_pts),
            "source": "biometric_history",
            "confidence": conf,
            "factors": factors,
            "charts": [chart],
            "summary": (
                f"Cân {latest:.1f}kg từ lịch sử thật; "
                f"~{kg_per_week:+.2f} kg/tuần (độ tin cậy: {conf})."
            ),
            "disclaimer": "Số liệu từ BiometricHistory — không phải tư vấn y khoa.",
        }

    # ── Fallback: energy-balance projection when history empty ───────────────
    nut = await dotnet.get_nutrition_timeseries(
        ctx.user_id,
        from_date=from_d.isoformat(),
        to_date=to_d.isoformat(),
        granularity="day",
    )
    wo = await dotnet.get_workout_timeseries(
        ctx.user_id,
        from_date=from_d.isoformat(),
        to_date=to_d.isoformat(),
        granularity="day",
        time_zone_id=resolve_tz_name(ctx),
    )
    nut_buckets = _unwrap_items(nut)
    wo_buckets = _unwrap_items(wo)

    cal_in_vals: list[float] = []
    logged = 0
    for b in nut_buckets:
        if not isinstance(b, dict):
            continue
        cin = b.get("consumedCalories", b.get("ConsumedCalories"))
        ml = int(b.get("mealsLoggedCount", b.get("MealsLoggedCount") or 0) or 0)
        if ml > 0 or (cin is not None and float(cin or 0) > 0):
            logged += 1
        if cin is not None:
            try:
                cal_in_vals.append(float(cin))
            except (TypeError, ValueError):
                pass

    burn = 0.0
    sessions = 0
    for b in wo_buckets:
        if not isinstance(b, dict):
            continue
        sessions += int(b.get("sessionsCompleted") or b.get("SessionsCompleted") or 0)
        try:
            burn += float(b.get("caloriesBurned") or b.get("CaloriesBurned") or 0)
        except (TypeError, ValueError):
            pass

    if weight is None:
        return {
            "status": "insufficient_data",
            "message": "Chưa có cân nặng hiện tại trong hồ sơ và chưa có BiometricHistory.",
            "charts": [],
        }

    ratio = logged / max(1, days)
    if ratio < 0.6 or sessions < 4:
        return {
            "status": "insufficient_data",
            "message": (
                f"Chưa có lịch sử cân; meal log {logged}/{days} ngày, "
                f"{sessions} buổi tập — chưa đủ để ước lượng."
            ),
            "confidence": "thấp",
            "factors": [f"meal {logged}/{days}", f"workout {sessions} buổi", "không có BiometricHistory"],
            "charts": [],
        }

    avg_in = _avg(cal_in_vals) or 0
    avg_burn_day = burn / max(1, days)
    energy_out = tdee if tdee > 0 else (avg_in)
    if tdee > 0 and avg_burn_day > 0:
        energy_out = tdee

    daily_balance = avg_in - energy_out
    kg_per_day = daily_balance / _KCAL_PER_KG
    kg_per_week = kg_per_day * 7

    n_pts = min(8, max(4, days // 7))
    x_labels = [f"T{i+1}" for i in range(n_pts)]
    hist = []
    for i in range(n_pts):
        weeks_ago = n_pts - 1 - i
        hist.append(round(weight - kg_per_week * weeks_ago, 2))
    proj = []
    for i in range(4):
        proj.append(round(weight + kg_per_week * (i + 1), 2))

    ann = [projection_annotation("Dự đoán", [None] * (n_pts - 1) + [hist[-1]] + proj)]
    if target:
        ann.append(target_line(target, label="Mục tiêu cân"))

    chart = chart_payload(
        chart_type="line",
        title=f"Cân nặng (ước lượng) — {label}",
        subtitle="Fallback cân bằng năng lượng (chưa có BiometricHistory)",
        unit="kg",
        granularity="week",
        x_labels=x_labels + [f"+{i+1}t" for i in range(4)],
        series=[
            series("Ước lượng", hist + [None] * 4),
            series("Dự đoán", [None] * (n_pts - 1) + [hist[-1]] + proj, style="dashed"),
            *([series("Mục tiêu", [target] * (n_pts + 4), style="dashed")] if target else []),
        ],
        annotations=ann,
        summary=(
            f"TB balance {daily_balance:+.0f} kcal/ngày → ~{kg_per_week:+.2f} kg/tuần. "
            "Chưa có lịch sử cân — đường là ước lượng."
        ),
    )
    if emit_charts:
        ctx.display_payload.append(chart)

    conf = _confidence(logged_ratio=ratio, workout_count=sessions, days=days)
    factors = [
        f"{logged}/{days} ngày meal log",
        f"{sessions} buổi tập",
        f"calo TB {avg_in:,.0f}",
        f"TDEE ~{energy_out:,.0f}" if energy_out else "thiếu TDEE",
        "fallback — không có BiometricHistory",
    ]
    if bf is not None:
        factors.append(f"% mỡ hiện tại {bf:.1f}% (1 điểm, chưa có trend)")

    return {
        "status": "ok",
        "period": label,
        "currentWeightKg": weight,
        "targetWeightKg": target,
        "kgPerWeekEstimate": kg_per_week,
        "dailyEnergyBalance": daily_balance,
        "source": "energy_balance_fallback",
        "confidence": conf,
        "factors": factors,
        "charts": [chart],
        "summary": (
            f"Cân hiện tại {weight:.1f}kg; ước {kg_per_week:+.2f} kg/tuần "
            f"(độ tin cậy: {conf}). Chưa có lịch sử cân — dùng cân bằng năng lượng."
        ),
        "disclaimer": "Ước lượng — không phải tư vấn y khoa.",
    }


async def predict_outcome(
    ctx: ToolRunContext,
    period: str = "8w",
    **_: Any,
) -> dict[str, Any]:
    if not insight_premium_allowed(_tier(ctx)):
        return _premium_block(ctx)

    body = await get_body_progress(ctx, period=period, emit_charts=True)
    if body.get("status") != "ok":
        return body

    adequacy = await evaluate_nutrition_adequacy(ctx, period=period, emit_charts=False)
    snap = ctx.state.get("user_snapshot") or {}
    weight = body.get("currentWeightKg") or _snap_num(snap, "currentWeightKg", "CurrentWeightKg")
    target = body.get("targetWeightKg") or _snap_num(snap, "targetWeightKg", "TargetWeightKg")
    kg_week = float(body.get("kgPerWeekEstimate") or 0)

    eta_weeks = None
    eta_message = "Chưa đặt mục tiêu cân."
    if weight is not None and target is not None and abs(kg_week) > 0.01:
        delta = target - weight
        if (delta > 0 and kg_week > 0) or (delta < 0 and kg_week < 0):
            eta_weeks = abs(delta / kg_week)
            eta_message = f"Với nhịp hiện tại, ETA khoảng {eta_weeks:.0f} tuần tới {target:.1f}kg."
        else:
            eta_message = (
                f"Nhịp hiện tại ({kg_week:+.2f} kg/tuần) đang đi ngược hướng mục tiêu "
                f"{target:.1f}kg — cần điều chỉnh."
            )

    factors = list(body.get("factors") or []) + list(adequacy.get("factors") or [])
    conf = body.get("confidence") or "thấp"
    if adequacy.get("confidence") == "thấp" or conf == "thấp":
        conf = "thấp"
    elif adequacy.get("confidence") == "trung bình" or conf == "trung bình":
        conf = "trung bình"

    message = (
        f"Dựa trên {', '.join(factors[:4])}: balance ~{body.get('dailyEnergyBalance'):+.0f} kcal/ngày "
        f"→ {kg_week:+.2f} kg/tuần. {eta_message} "
        f"Dinh dưỡng: {adequacy.get('verdict', '—')} (độ tin cậy: {conf}). "
        "Đây là ước lượng từ nhiều nguồn thật, không phải tư vấn y khoa."
    )
    return {
        "status": "ok",
        "etaWeeks": eta_weeks,
        "kgPerWeekEstimate": kg_week,
        "nutritionVerdict": adequacy.get("verdict"),
        "confidence": conf,
        "factors": factors,
        "message": message,
        "body": {k: body[k] for k in ("currentWeightKg", "targetWeightKg", "dailyEnergyBalance") if k in body},
        "disclaimer": "Ước lượng heuristic (7700 kcal/kg); không thay thế chuyên gia.",
    }


async def build_insight_dashboard(
    ctx: ToolRunContext,
    period: str = "8w",
    focus: str = "all",
    **_: Any,
) -> dict[str, Any]:
    if not insight_premium_allowed(_tier(ctx)):
        return _premium_block(ctx)

    focus_l = (focus or "all").lower()
    factors: list[str] = []
    parts: list[str] = []
    collected: list[dict[str, Any]] = []
    verdict = ""
    conf = "trung bình"

    nut = wo = body = pred = adeq = None

    if focus_l in ("all", "nutrition", "diet", "an", "dinh duong", "dinh dưỡng"):
        nut = await get_nutrition_stats(ctx, period=period, granularity="week", emit_charts=False)
        if nut.get("status") == "premium_required":
            return nut
        collected.extend(nut.get("charts") or [])
        parts.append(nut.get("summary") or "")
        factors.extend(nut.get("factors") or [])
        adeq = await evaluate_nutrition_adequacy(ctx, period=period, emit_charts=False)
        collected.extend(adeq.get("charts") or [])
        parts.append(adeq.get("message") or "")
        factors.extend(adeq.get("factors") or [])
        verdict = str(adeq.get("verdict") or "")
        conf = str(adeq.get("confidence") or conf)

    if focus_l in ("all", "workout", "tap", "tập", "training"):
        wo = await get_workout_stats(ctx, period=period, granularity="week", emit_charts=False)
        if wo.get("status") != "insufficient_data":
            collected.extend(wo.get("charts") or [])
            parts.append(wo.get("summary") or "")
            factors.extend(wo.get("factors") or [])
            if wo.get("confidence") == "thấp":
                conf = "thấp"

    if focus_l in ("all", "body", "weight", "can", "cân", "progress"):
        body = await get_body_progress(ctx, period=period, emit_charts=False)
        if body.get("status") == "ok":
            collected.extend(body.get("charts") or [])
            parts.append(body.get("summary") or "")
            factors.extend(body.get("factors") or [])
            # ETA without re-emitting charts
            weight = body.get("currentWeightKg")
            target = body.get("targetWeightKg")
            kg_week = float(body.get("kgPerWeekEstimate") or 0)
            if weight is not None and target is not None and abs(kg_week) > 0.01:
                delta = target - weight
                if (delta > 0 and kg_week > 0) or (delta < 0 and kg_week < 0):
                    eta = abs(delta / kg_week)
                    verdict = (f"{verdict} | ETA ~{eta:.0f} tuần").strip(" |")
                    parts.append(f"ETA khoảng {eta:.0f} tuần tới mục tiêu {target}kg.")
            if body.get("confidence") == "thấp":
                conf = "thấp"

    dash = insight_dashboard(
        charts=collected[:8],
        verdict=verdict or (parts[0][:160] if parts else "Tổng quan Insight"),
        confidence=conf,
        factors=list(dict.fromkeys(factors))[:12],
        period_label=str(period),
    )
    ctx.display_payload.append(dash)
    return {
        "status": "ok",
        "period": period,
        "focus": focus_l,
        "charts": len(collected),
        "verdict": dash.get("verdict"),
        "confidence": conf,
        "factors": dash.get("factors"),
        "message": " ".join(p for p in parts if p)[:800],
        "disclaimer": "Tổng hợp từ meal logs + workout logs + hồ sơ; ước lượng, không phải tư vấn y khoa.",
    }