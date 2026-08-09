"""Adaptive Coaching Engine — pipeline tất định theo docs/ai-agents/SYNC-Adaptive-Coaching-Engine-Design.md.

Nguyên tắc số 1: LLM KHÔNG tính toán. Mọi con số ở đây là công thức minh bạch
(EMA, cân bằng năng lượng, Mifflin-St Jeor, rào an toàn) — LLM chỉ diễn giải
AdjustmentPlan trả về. Toàn bộ hàm pure → unit-test không cần mock mạng.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from typing import Any

# ── Hằng số theo thiết kế ────────────────────────────────────────────────────
KCAL_PER_KG = 7700.0
EMA_ALPHA = 0.25              # ~làm mượt 7 ngày
OUTLIER_KG = 2.0              # loại số cân lệch >±2kg so với EMA (nghi cân sai)
WINDOW_DAYS = 14              # cửa sổ ước lượng TDEE
MIN_LOG_DAYS = 10             # tối thiểu ngày có log ăn trong cửa sổ
MIN_WEIGHINS = 2              # tối thiểu số lần cân
MIN_WEIGHIN_SPAN_DAYS = 7    # 2 lần cân phải cách nhau ≥7 ngày
MAX_STEP_KCAL = 200.0         # bước chỉnh tối đa mỗi lần
MAX_STEP_PCT = 0.10           # ±10% mỗi lần
MAX_DEFICIT_PCT = 0.25        # trần deficit 25% TDEE
CAL_FLOOR_MALE = 1500.0
CAL_FLOOR_FEMALE = 1200.0

ACTIVITY_FACTORS = {
    "sedentary": 1.2,
    "lightlyactive": 1.375,
    "moderatelyactive": 1.55,
    "veryactive": 1.725,
    "extraactive": 1.9,
}

# %BW/tuần mục tiêu theo goal (thiết kế §3.5)
RATE_TARGETS = {
    "deficit": (0.005, 0.010),   # giảm mỡ 0.5–1.0 %BW/tuần
    "surplus": (0.0025, 0.005),  # tăng cơ 0.25–0.5 %BW/tuần
    "maintain": (0.0, 0.0),
}


def goal_kind(goal: str | None) -> str:
    g = str(goal or "").lower()
    if any(k in g for k in ("lose", "fat", "cut", "giảm", "giam")):
        return "deficit"
    if any(k in g for k in ("gain", "muscle", "bulk", "tăng", "tang")):
        return "surplus"
    return "maintain"


# ── §3.1 Làm sạch cân nặng ───────────────────────────────────────────────────
def ema_series(points: list[tuple[date, float]], alpha: float = EMA_ALPHA) -> list[tuple[date, float]]:
    """EMA + loại outlier >±OUTLIER_KG so với EMA hiện hành. points phải sort theo ngày."""
    out: list[tuple[date, float]] = []
    ema: float | None = None
    for d, w in sorted(points, key=lambda p: p[0]):
        if w <= 0:
            continue
        if ema is not None and abs(w - ema) > OUTLIER_KG:
            continue  # nghi cân sai/nhiễu nước — bỏ, giữ EMA cũ
        ema = w if ema is None else alpha * w + (1 - alpha) * ema
        out.append((d, round(ema, 3)))
    return out


# ── §3.2 TDEE thực từ cân bằng năng lượng ────────────────────────────────────
def estimate_tdee_actual(avg_intake_kcal: float, delta_w_kg: float, days: int) -> float:
    """delta_w_kg DƯƠNG = giảm cân. TDEE_actual = intake + ΔW×7700/N."""
    if days <= 0:
        return avg_intake_kcal
    return avg_intake_kcal + (delta_w_kg * KCAL_PER_KG / days)


# ── §3.3 Nền lý thuyết + blend ───────────────────────────────────────────────
def mifflin_bmr(sex: str, weight_kg: float, height_cm: float, age_years: float) -> float:
    s = 5.0 if str(sex or "").lower().startswith(("m", "nam")) else -161.0
    return 10.0 * weight_kg + 6.25 * height_cm - 5.0 * age_years + s


def tdee_formula(bmr: float, activity_level: str | None) -> float:
    key = str(activity_level or "").replace(" ", "").replace("_", "").lower()
    return bmr * ACTIVITY_FACTORS.get(key, 1.4)


def confidence_weight(
    *,
    logged_days: int,
    window_days: int = WINDOW_DAYS,
    weighin_count: int,
    weighin_span_days: int,
    weight_variance_kg: float = 0.0,
) -> float:
    """w ∈ [0,1] — tăng theo độ phủ log ăn, số lần cân, độ ổn định."""
    if logged_days < MIN_LOG_DAYS or weighin_count < MIN_WEIGHINS or weighin_span_days < MIN_WEIGHIN_SPAN_DAYS:
        return 0.0
    log_part = min(1.0, logged_days / window_days)                # 10/14→0.71 … 14/14→1
    weigh_part = min(1.0, weighin_count / 7.0)                    # cân đều mỗi 2 ngày → 1
    stability = 1.0 / (1.0 + max(0.0, weight_variance_kg - 0.3))  # phương sai lớn → giảm tin
    return round(max(0.0, min(1.0, 0.5 * log_part + 0.3 * weigh_part + 0.2 * stability)), 3)


def confidence_label(w: float) -> str:
    if w >= 0.7:
        return "cao"
    if w >= 0.4:
        return "trung bình"
    return "thấp"


def blend_tdee(tdee_actual: float, tdee_formula_val: float, w: float) -> float:
    return w * tdee_actual + (1 - w) * tdee_formula_val


# ── §3.4 Targets calo & macro theo kg ────────────────────────────────────────
def macro_coefficients(kind: str, level_tier: str) -> tuple[float, float]:
    """(k_p protein g/kg, k_f fat g/kg). Cắt mỡ & Advanced → protein cao hơn."""
    advanced = level_tier == "Advanced"
    if kind == "deficit":
        return (2.2 if advanced else 2.0, 0.7)
    if kind == "surplus":
        return (2.0 if advanced else 1.8, 0.8)
    return (1.6, 0.8)


def compute_targets(
    *,
    kind: str,
    tdee_used: float,
    weight_kg: float,
    level_tier: str = "Beginner",
    deficit_pct: float = 0.15,
    surplus_pct: float = 0.10,
) -> dict[str, float]:
    if kind == "deficit":
        calories = tdee_used * (1 - min(deficit_pct, MAX_DEFICIT_PCT))
    elif kind == "surplus":
        calories = tdee_used * (1 + min(max(surplus_pct, 0.05), 0.15))
    else:
        calories = tdee_used
    k_p, k_f = macro_coefficients(kind, level_tier)
    protein_g = k_p * weight_kg
    fat_g = k_f * weight_kg
    carb_g = max(0.0, (calories - 4 * protein_g - 9 * fat_g) / 4)
    return {
        "calories": round(calories),
        "protein_g": round(protein_g),
        "fat_g": round(fat_g),
        "carb_g": round(carb_g),
    }


# ── §3.5 Hiệu chỉnh theo tốc độ thực ─────────────────────────────────────────
def is_rate_off_target(kind: str, rate_actual_pct_bw: float) -> bool:
    lo, hi = RATE_TARGETS.get(kind, (0.0, 0.0))
    if kind == "deficit":
        return rate_actual_pct_bw < lo or rate_actual_pct_bw > hi
    if kind == "surplus":
        return rate_actual_pct_bw > -lo or rate_actual_pct_bw < -hi
    return False


def count_consecutive_off_target_weeks(
    smoothed: list[tuple[date, float]],
    kind: str,
) -> int:
    """Đếm số tuần liên tiếp (từ cuối) tốc độ lệch mục tiêu — cần ≥2 để rate-correct."""
    if len(smoothed) < 2 or kind == "maintain":
        return 0
    # Ghép điểm theo ISO week, lấy first/last weight mỗi tuần
    by_week: dict[tuple[int, int], list[tuple[date, float]]] = {}
    for d, w in smoothed:
        key = (d.isocalendar()[0], d.isocalendar()[1])
        by_week.setdefault(key, []).append((d, w))
    weeks = sorted(by_week.keys())
    if len(weeks) < 2:
        # Một cửa sổ dài ≥7 ngày → coi như 1 "tuần" off/on
        span = (smoothed[-1][0] - smoothed[0][0]).days
        if span < 7:
            return 0
        w0, w1 = smoothed[0][1], smoothed[-1][1]
        if w1 <= 0:
            return 0
        weeks_n = max(span / 7.0, 1.0)
        rate = ((w0 - w1) / w1) / weeks_n
        return 1 if is_rate_off_target(kind, rate) else 0

    consecutive = 0
    for key in reversed(weeks):
        pts = sorted(by_week[key], key=lambda p: p[0])
        if len(pts) < 2:
            # single weigh-in week — so sánh với tuần trước nếu có
            continue
        w0, w1 = pts[0][1], pts[-1][1]
        if w1 <= 0:
            break
        days = max((pts[-1][0] - pts[0][0]).days, 1)
        rate = ((w0 - w1) / w1) / (days / 7.0)
        if is_rate_off_target(kind, rate):
            consecutive += 1
        else:
            break
    return consecutive


def rate_correction_kcal(
    *,
    kind: str,
    rate_actual_pct_bw: float,   # %BW/tuần, DƯƠNG = giảm
    target_calories: float,
    consecutive_off_target_weeks: int = 2,
) -> tuple[float, str]:
    """Trả (Δkcal, reason_code). Δ<0 = hạ calo. Chỉ chỉnh sau ≥2 tuần lệch liên tiếp."""
    if consecutive_off_target_weeks < 2:
        return (0.0, "awaiting_2_weeks")
    lo, hi = RATE_TARGETS.get(kind, (0.0, 0.0))
    step_cap = min(MAX_STEP_KCAL, MAX_STEP_PCT * target_calories)
    if kind == "deficit":
        if rate_actual_pct_bw < lo:   # giảm quá chậm → hạ calo
            return (-step_cap, "rate_too_slow")
        if rate_actual_pct_bw > hi:   # giảm quá nhanh → NÂNG calo giữ cơ
            return (step_cap, "rate_too_fast")
    elif kind == "surplus":
        if rate_actual_pct_bw > -lo:  # tăng cân quá chậm (rate giảm dương) → nâng calo
            return (step_cap, "gain_too_slow")
        if rate_actual_pct_bw < -hi:  # tăng quá nhanh → hạ nhẹ
            return (-step_cap, "gain_too_fast")
    return (0.0, "on_track")


# ── §5 Rào an toàn ───────────────────────────────────────────────────────────
def apply_safety_rails(
    *,
    calories: float,
    bmr: float,
    tdee_used: float,
    sex: str,
    old_protein_g: float | None,
    protein_g: float,
    kind: str,
) -> tuple[float, float, list[str]]:
    """Trả (calories_safe, protein_safe, flags)."""
    flags: list[str] = []
    floor = max(bmr * 1.1, CAL_FLOOR_MALE if str(sex or "").lower().startswith(("m", "nam")) else CAL_FLOOR_FEMALE)
    if calories < floor:
        calories = floor
        flags.append("calorie_floor")
    if kind == "deficit" and tdee_used > 0:
        min_cal = tdee_used * (1 - MAX_DEFICIT_PCT)
        if calories < min_cal:
            calories = min_cal
            flags.append("deficit_cap_25pct")
    # Protein không giảm khi đang cắt calo (giữ cơ)
    if old_protein_g and kind == "deficit" and protein_g < old_protein_g:
        protein_g = old_protein_g
        flags.append("protein_kept")
    return (round(calories), round(protein_g), flags)


# ── §3.6 Điều chỉnh tập luyện ────────────────────────────────────────────────
def training_adjustment(
    *,
    completion_rate: float,     # 0..1
    volume_trend_pct: float,    # % thay đổi VolumeLoad tuần gần vs trước
    recovery_index: float,      # 0..10 (cao = phục hồi tốt)
    new_injury: bool = False,
) -> dict[str, Any]:
    if new_injury:
        return {"action": "substitute", "detail": "Thay bài an toàn theo luật substitution (có chấn thương mới)."}
    if completion_rate < 0.60 or recovery_index < 4.0:
        return {"action": "deload", "volume_change_pct": -30,
                "detail": "Giảm 20–40% volume 1 tuần (completion thấp/recovery kém)."}
    if completion_rate >= 0.85 and volume_trend_pct >= 0 and recovery_index >= 6.0:
        return {"action": "progress", "load_change_pct": 2.5,
                "detail": "Tăng 2.5–5% tải hoặc +1 set bài chính."}
    return {"action": "hold", "detail": "Giữ nguyên, siết kỹ thuật."}


# ── §3.7 Trình độ ────────────────────────────────────────────────────────────
def level_score(
    *,
    consistency: float,        # 0..100
    progression: float,        # 0..100
    recovery_capacity: float,  # 0..100
    experience_base: float,    # 0..100 (từ experienceLevel hồ sơ)
) -> tuple[float, str]:
    score = 0.30 * consistency + 0.30 * progression + 0.20 * recovery_capacity + 0.20 * experience_base
    score = round(max(0.0, min(100.0, score)), 1)
    tier = "Beginner" if score < 35 else ("Intermediate" if score <= 70 else "Advanced")
    return (score, tier)


def experience_base_from_profile(experience_level: str | None) -> float:
    key = str(experience_level or "").lower()
    if "advanced" in key:
        return 85.0
    if "intermediate" in key:
        return 55.0
    return 25.0


# ── §3.8 ETA ─────────────────────────────────────────────────────────────────
def eta_weeks(w_ema: float, w_target: float, rate_kg_per_week: float) -> float | None:
    """rate DƯƠNG = giảm. None nếu rate ~0 hoặc đã đạt/ngược hướng."""
    remaining = w_ema - w_target
    if abs(rate_kg_per_week) < 0.02 or remaining == 0:
        return None
    weeks = remaining / rate_kg_per_week
    return round(weeks, 1) if weeks > 0 else None


# ── §7 Phân mức thay đổi ─────────────────────────────────────────────────────
def classify_change(
    *,
    old_calories: float | None,
    new_calories: float,
    training_action: str,
    phase_changed: bool = False,
) -> str:
    if phase_changed or training_action == "deload":
        return "large"
    if not old_calories or old_calories <= 0:
        return "medium"
    pct = abs(new_calories - old_calories) / old_calories
    if pct <= 0.05 and training_action in ("hold",):
        return "small"
    if pct <= 0.10:
        return "medium"
    return "large"


# ── Orchestrator: build AdjustmentPlan ───────────────────────────────────────
@dataclass
class EngineInput:
    # Hồ sơ
    sex: str = "male"
    age_years: float = 30
    bmr_override: float | None = None  # snapshot IAM có BMR sẵn (không có DOB)
    height_cm: float = 170
    activity_level: str = "ModeratelyActive"
    fitness_goal: str = "LoseFat"
    experience_level: str = "Beginner"
    target_weight_kg: float | None = None
    # Chuỗi cân nặng (date, kg) — thô, engine tự EMA
    weighins: list[tuple[date, float]] = field(default_factory=list)
    # Dinh dưỡng cửa sổ N ngày
    avg_intake_kcal: float | None = None
    logged_days: int = 0
    window_days: int = WINDOW_DAYS
    # Targets hiện tại (để so cũ→mới + rào protein)
    old_calories: float | None = None
    old_protein_g: float | None = None
    old_carb_g: float | None = None
    old_fat_g: float | None = None
    # Tập luyện
    completion_rate: float = 0.0
    volume_trend_pct: float = 0.0
    recovery_index: float = 6.0
    consistency_score: float = 0.0
    progression_score: float = 0.0
    recovery_capacity_score: float = 50.0
    new_injury: bool = False
    # §3.5 / §7 ops gates
    consecutive_off_target_weeks: int | None = None  # None → derive from weighins
    days_since_last_adjustment: int | None = None    # None → không cap
    volume_load_weekly: float = 0.0


def build_adjustment_plan(inp: EngineInput) -> dict[str, Any]:
    """Chạy full pipeline §3 → AdjustmentPlan JSON-able. Pure — không I/O."""
    kind = goal_kind(inp.fitness_goal)
    reasons: list[str] = []
    factors: list[str] = []

    # 1) EMA cân nặng
    smoothed = ema_series(inp.weighins)
    w_now = smoothed[-1][1] if smoothed else 0.0
    w_start = smoothed[0][1] if smoothed else 0.0
    span_days = (smoothed[-1][0] - smoothed[0][0]).days if len(smoothed) >= 2 else 0
    factors.append(f"{len(smoothed)} lần cân hợp lệ trong {span_days} ngày")

    # 2+3) TDEE
    bmr = inp.bmr_override if inp.bmr_override and inp.bmr_override > 0 else mifflin_bmr(
        inp.sex, w_now or 70.0, inp.height_cm, inp.age_years,
    )
    tdee_f = tdee_formula(bmr, inp.activity_level)
    variance = 0.0
    if len(smoothed) >= 3:
        vals = [w for _, w in smoothed]
        mean = sum(vals) / len(vals)
        variance = (sum((v - mean) ** 2 for v in vals) / len(vals)) ** 0.5
    w_conf = confidence_weight(
        logged_days=inp.logged_days,
        window_days=inp.window_days,
        weighin_count=len(smoothed),
        weighin_span_days=span_days,
        weight_variance_kg=variance,
    )
    sufficient = w_conf > 0.0
    delta_w = w_start - w_now  # dương = giảm
    tdee_a = (
        estimate_tdee_actual(inp.avg_intake_kcal, delta_w, span_days)
        if sufficient and inp.avg_intake_kcal
        else tdee_f
    )
    tdee_used = blend_tdee(tdee_a, tdee_f, w_conf)
    factors.append(f"{inp.logged_days}/{inp.window_days} ngày có log ăn")
    if sufficient:
        reasons.append(
            f"TDEE thực ước tính ~{tdee_a:,.0f} kcal (ăn TB {inp.avg_intake_kcal:,.0f}, "
            f"Δcân {delta_w:+.2f}kg/{span_days} ngày) — blend {w_conf:.0%} với công thức {tdee_f:,.0f}."
        )
    else:
        reasons.append(
            "Chưa đủ dữ liệu hiệu chỉnh TDEE thực (cần ≥10/14 ngày log ăn + ≥2 lần cân cách ≥7 ngày) "
            "— dùng công thức Mifflin, KHÔNG chỉnh mạnh."
        )

    # 5) Level (tất định — tính on-the-fly, chưa cần bảng snapshot)
    score, tier = level_score(
        consistency=inp.consistency_score,
        progression=inp.progression_score,
        recovery_capacity=inp.recovery_capacity_score,
        experience_base=experience_base_from_profile(inp.experience_level),
    )

    # 4) Targets mới theo kg
    targets = compute_targets(kind=kind, tdee_used=tdee_used, weight_kg=w_now or 70.0, level_tier=tier)

    # §3.5 hiệu chỉnh theo tốc độ (chỉ khi đủ dữ liệu ≥2 tuần + ≥2 tuần lệch liên tiếp)
    rate_actual = 0.0
    off_weeks = inp.consecutive_off_target_weeks
    if off_weeks is None:
        off_weeks = count_consecutive_off_target_weeks(smoothed, kind)
    if sufficient and span_days >= 14 and w_now > 0:
        weeks = span_days / 7.0
        rate_actual = (delta_w / w_now) / weeks
        d_kcal, rate_code = rate_correction_kcal(
            kind=kind,
            rate_actual_pct_bw=rate_actual,
            target_calories=targets["calories"],
            consecutive_off_target_weeks=off_weeks,
        )
        if d_kcal != 0.0:
            targets["calories"] = round(targets["calories"] + d_kcal)
            targets["carb_g"] = round(max(0.0, (targets["calories"] - 4 * targets["protein_g"] - 9 * targets["fat_g"]) / 4))
            reasons.append(
                f"Tốc độ thực {rate_actual * 100:.2f}%BW/tuần lệch mục tiêu → chỉnh {d_kcal:+.0f} kcal ({rate_code})."
            )
        elif rate_code == "awaiting_2_weeks" and is_rate_off_target(kind, rate_actual):
            reasons.append(
                f"Tốc độ {rate_actual * 100:.2f}%BW/tuần lệch mục tiêu nhưng mới {off_weeks} tuần liên tiếp "
                "— chờ đủ 2 tuần trước khi chỉnh calo."
            )

    # §5 rào an toàn
    cal_safe, protein_safe, flags = apply_safety_rails(
        calories=targets["calories"], bmr=bmr, tdee_used=tdee_used, sex=inp.sex,
        old_protein_g=inp.old_protein_g, protein_g=targets["protein_g"], kind=kind,
    )
    if cal_safe != targets["calories"] or protein_safe != targets["protein_g"]:
        targets["calories"] = cal_safe
        targets["protein_g"] = protein_safe
        targets["carb_g"] = round(max(0.0, (cal_safe - 4 * protein_safe - 9 * targets["fat_g"]) / 4))
    for f in flags:
        reasons.append({"calorie_floor": "Chạm sàn calo an toàn — không hạ thêm.",
                        "deficit_cap_25pct": "Chạm trần deficit 25% TDEE.",
                        "protein_kept": "Giữ nguyên protein khi cắt calo (bảo toàn cơ)."}[f])

    # 6) Training adjustment
    training = training_adjustment(
        completion_rate=inp.completion_rate,
        volume_trend_pct=inp.volume_trend_pct,
        recovery_index=inp.recovery_index,
        new_injury=inp.new_injury,
    )

    # 8) ETA
    eta = None
    if inp.target_weight_kg and w_now > 0 and rate_actual != 0:
        eta = eta_weeks(w_now, inp.target_weight_kg, rate_actual * w_now)

    change = classify_change(
        old_calories=inp.old_calories,
        new_calories=targets["calories"],
        training_action=training["action"],
    )
    # Thiếu dữ liệu → không auto, không đề xuất mạnh
    if not sufficient and change == "large":
        change = "medium"

    # Max 1 calorie adjustment / tuần
    calorie_changed = (
        inp.old_calories is not None
        and abs(targets["calories"] - inp.old_calories) >= 1
    )
    weekly_cap_hit = (
        inp.days_since_last_adjustment is not None
        and inp.days_since_last_adjustment < 7
        and calorie_changed
    )
    if weekly_cap_hit:
        change = "small"  # soft
        reasons.append(
            f"Đã chỉnh targets {inp.days_since_last_adjustment} ngày trước — "
            "giới hạn 1 lần/tuần: đề xuất mềm, không auto-apply calo."
        )

    auto_apply = change == "small" and sufficient and not weekly_cap_hit

    return {
        "weight": {"ema_kg": w_now, "raw_latest_kg": inp.weighins[-1][1] if inp.weighins else None,
                   "delta_kg_window": round(delta_w, 2), "span_days": span_days},
        "tdee": {"actual": round(tdee_a), "formula": round(tdee_f), "used": round(tdee_used),
                 "bmr": round(bmr), "blend_w": w_conf},
        "targets_old": {"calories": inp.old_calories, "protein_g": inp.old_protein_g,
                        "carb_g": inp.old_carb_g, "fat_g": inp.old_fat_g},
        "targets_new": targets,
        "rate": {
            "actual_pct_bw_week": round(rate_actual * 100, 3),
            "consecutive_off_target_weeks": off_weeks,
        },
        "training": training,
        "level": {
            "score": score,
            "tier": tier,
            "consistency": inp.consistency_score,
            "progression": inp.progression_score,
            "recovery_capacity": inp.recovery_capacity_score,
            "volume_load_weekly": inp.volume_load_weekly,
        },
        "eta_weeks": eta,
        "goal_kind": kind,
        "change_class": change,           # small → auto · medium/large → confirm
        # §6: thiếu dữ liệu → KHÔNG auto-apply dù thay đổi nhỏ (chỉ đề xuất + confirm)
        "auto_apply": auto_apply,
        "weekly_cap_hit": weekly_cap_hit,
        "confidence": confidence_label(w_conf),
        "data_sufficient": sufficient,
        "safety_flags": flags,
        "reasons": reasons,
        "factors": factors,
    }
