"""Demo seed expectations for tool contract validation.

Constants mirror C# seed files:
- IamSeedData.cs (gamification, biometrics)
- RoadmapSeedData.cs (roadmap, sessions, recovery)
- NutritionSeedData.cs (macro targets, today summary)
- PaymentSeedData.cs (wallet coins, vouchers)
"""
from __future__ import annotations

from typing import Any

# ── Identity ──────────────────────────────────────────────────────────────────
DEMO_USER_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
DEMO_EMAIL = "demo@sync.local"

# ── IAM gamification (IamSeedData) ────────────────────────────────────────────
EXPECT_GAMIFICATION = {
    "currentLevel": 7,
    "currentXP": 1840,
    "currentStreak": 12,
    "syncCoins": 340,
}

# ── Roadmap (RoadmapSeedData) ─────────────────────────────────────────────────
EXPECT_ROADMAP_ID = "f1000001-0000-0000-0000-000000000001"
EXPECT_ROADMAP_NAME = "Demo Fat Loss 12W"
EXPECT_ROADMAP_STATUS = "Active"
EXPECT_CURRENT_WEIGHT_KG = 78
EXPECT_TARGET_WEIGHT_KG = 72
EXPECT_TODAY_SESSION_ID = "f4000007-0000-0000-0000-000000000007"
SEED_PUSH_UP_EXERCISE_ID = "11111111-1111-1111-1111-111111111111"
SEED_RICE_FOOD_ID = "f1000001-0000-0000-0000-000000000001"

# ── Recovery (RoadmapSeedData demo recovery profile) ────────────────────────
EXPECT_RECOVERY_SCORE = 72

# ── Nutrition (NutritionSeedData / IAM biometrics) ────────────────────────────
EXPECT_MACRO_TARGETS = {
    "targetCalories": 2180,
    "targetProteinGram": 150,
    "targetCarbGram": 220,
    "targetFatGram": 65,
}
EXPECT_TODAY_MIN = {
    "waterIntakeMl": 1200,
    "mealsLoggedCount": 3,
}

# ── Payment API surface (OrderPaymentService.GetWalletBalanceAsync) ───────────
EXPECT_WALLET_COINS = 340
EXPECT_VOUCHER_CODES = frozenset({"DEMO10K", "DEMO15PCT"})

CONTRACT_TOOLS = frozenset({
    "get_gamification_status",
    "get_active_roadmap",
    "get_today_workout",
    "get_daily_summary",
    "check_wallet",
    "list_vouchers",
    "get_nutrition_targets",
    "get_recovery_status",
    "search_exercises",
    "search_food",
    "search_partners",
    "get_roadmap_sessions",
})


def _first_value(obj: Any, *keys: str) -> Any:
    if not isinstance(obj, dict):
        return None
    for key in keys:
        if key in obj and obj[key] is not None:
            return obj[key]
    lower = {str(k).lower(): v for k, v in obj.items()}
    for key in keys:
        lk = key.lower()
        if lk in lower and lower[lk] is not None:
            return lower[lk]
    return None


def _items_list(result: dict[str, Any]) -> list[dict[str, Any]]:
    for key in ("items", "Items", "data", "Data", "value"):
        raw = result.get(key)
        if isinstance(raw, list):
            return [x for x in raw if isinstance(x, dict)]
    return []


def _check_eq(
    errors: list[str],
    result: dict[str, Any],
    field: str,
    expected: Any,
    *,
    tol: float = 0.01,
) -> None:
    actual = _first_value(result, field)
    if actual is None:
        errors.append(f"{field}: missing (expected {expected!r})")
        return
    if isinstance(expected, (int, float)) and isinstance(actual, (int, float)):
        if abs(float(actual) - float(expected)) > tol:
            errors.append(f"{field}: expected {expected!r}, got {actual!r}")
        return
    if isinstance(expected, str):
        if str(actual).lower() != expected.lower():
            errors.append(f"{field}: expected {expected!r}, got {actual!r}")
        return
    if actual != expected:
        errors.append(f"{field}: expected {expected!r}, got {actual!r}")


def _check_gte(errors: list[str], result: dict[str, Any], field: str, minimum: Any) -> None:
    actual = _first_value(result, field)
    if actual is None:
        errors.append(f"{field}: missing (expected >= {minimum!r})")
        return
    if float(actual) < float(minimum):
        errors.append(f"{field}: expected >= {minimum!r}, got {actual!r}")


def _check_non_empty_list(errors: list[str], result: dict[str, Any], label: str = "items") -> list[dict[str, Any]]:
    items = _items_list(result)
    if not items:
        errors.append(f"{label}: expected non-empty list")
    return items


def _check_gamification(result: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for field, expected in EXPECT_GAMIFICATION.items():
        _check_eq(errors, result, field, expected)
    return errors


def _check_roadmap(result: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    _check_eq(errors, result, "id", EXPECT_ROADMAP_ID)
    _check_eq(errors, result, "roadmapName", EXPECT_ROADMAP_NAME)
    _check_eq(errors, result, "roadmapStatus", EXPECT_ROADMAP_STATUS)
    _check_eq(errors, result, "currentWeightKg", EXPECT_CURRENT_WEIGHT_KG)
    _check_eq(errors, result, "targetWeightKg", EXPECT_TARGET_WEIGHT_KG)
    return errors


def _check_today_workout(result: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    scheduled = _first_value(result, "hasWorkoutScheduledToday", "HasWorkoutScheduledToday")
    if scheduled is not True:
        errors.append(f"hasWorkoutScheduledToday: expected True, got {scheduled!r}")

    name = _first_value(result, "todayWorkoutName", "TodayWorkoutName") or ""
    if "hôm nay" not in str(name).lower() and "upper push" not in str(name).lower():
        errors.append(f"todayWorkoutName: expected demo today session title, got {name!r}")

    # sessionId is only populated after a workout log exists (.NET InternalWorkoutActivityService).
    # When scheduled-but-not-started, assert name/flag only; if present, must match seed.
    session_id = _first_value(result, "sessionId", "SessionId")
    if session_id is not None and str(session_id).lower() != EXPECT_TODAY_SESSION_ID.lower():
        errors.append(f"sessionId: expected {EXPECT_TODAY_SESSION_ID}, got {session_id!r}")
    return errors


def _check_daily_summary(result: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for field, expected in EXPECT_MACRO_TARGETS.items():
        _check_eq(errors, result, field, expected)
    for field, minimum in EXPECT_TODAY_MIN.items():
        _check_gte(errors, result, field, minimum)
    return errors


def _check_wallet(result: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    coins = _first_value(result, "coinBalance", "CoinBalance", "availableBalance", "AvailableBalance")
    if coins is None:
        errors.append("coinBalance: missing")
    elif float(coins) != float(EXPECT_WALLET_COINS):
        errors.append(f"coinBalance: expected {EXPECT_WALLET_COINS}, got {coins!r}")
    return errors


def _check_vouchers(result: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    items = _check_non_empty_list(errors, result, "vouchers")
    if len(items) < 2:
        errors.append(f"vouchers: expected >= 2 items, got {len(items)}")
    codes: set[str] = set()
    for item in items:
        code = _first_value(item, "code", "Code", "couponCode", "CouponCode", "voucherCode")
        if code:
            codes.add(str(code).upper())
    missing = {c.upper() for c in EXPECT_VOUCHER_CODES} - codes
    if missing:
        errors.append(f"vouchers: missing codes {sorted(missing)} (found {sorted(codes)})")
    return errors


def _check_nutrition_targets(result: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for field, expected in EXPECT_MACRO_TARGETS.items():
        _check_eq(errors, result, field, expected)
    return errors


def _check_recovery(result: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    _check_eq(errors, result, "currentRecoveryScore", EXPECT_RECOVERY_SCORE)
    return errors


def _check_search_exercises(result: dict[str, Any], *, kwargs: dict[str, Any] | None) -> list[str]:
    errors: list[str] = []
    _check_non_empty_list(errors, result, "exercises")
    return errors


def _check_search_food(result: dict[str, Any], **_kwargs: Any) -> list[str]:
    errors: list[str] = []
    _check_non_empty_list(errors, result, "foods")
    return errors


def _check_search_partners(result: dict[str, Any], **_kwargs: Any) -> list[str]:
    errors: list[str] = []
    _check_non_empty_list(errors, result, "partners")
    return errors


def _check_roadmap_sessions(result: dict[str, Any], **_kwargs: Any) -> list[str]:
    errors: list[str] = []
    items = _check_non_empty_list(errors, result, "sessions")
    if items and len(items) < 1:
        errors.append("sessions: expected >= 1 session")
    session_ids = {str(_first_value(it, "id", "Id") or "").lower() for it in items}
    if EXPECT_TODAY_SESSION_ID.lower() not in session_ids:
        errors.append(f"sessions: expected today session {EXPECT_TODAY_SESSION_ID} in list")
    return errors


_VALIDATORS: dict[str, Any] = {
    "get_gamification_status": lambda r, **kw: _check_gamification(r),
    "get_active_roadmap": lambda r, **kw: _check_roadmap(r),
    "get_today_workout": lambda r, **kw: _check_today_workout(r),
    "get_daily_summary": lambda r, **kw: _check_daily_summary(r),
    "check_wallet": lambda r, **kw: _check_wallet(r),
    "list_vouchers": lambda r, **kw: _check_vouchers(r),
    "get_nutrition_targets": lambda r, **kw: _check_nutrition_targets(r),
    "get_recovery_status": lambda r, **kw: _check_recovery(r),
    "search_exercises": _check_search_exercises,
    "search_food": _check_search_food,
    "search_partners": _check_search_partners,
    "get_roadmap_sessions": _check_roadmap_sessions,
}


def validate_contract(
    tool_name: str,
    result: dict[str, Any],
    *,
    kwargs: dict[str, Any] | None = None,
) -> list[str]:
    """Return list of contract violation messages (empty if OK)."""
    if tool_name not in CONTRACT_TOOLS:
        return []
    if not isinstance(result, dict):
        return ["result is not a dict"]
    if result.get("error"):
        return [f"tool error: {result['error']}"]
    validator = _VALIDATORS.get(tool_name)
    if not validator:
        return []
    return validator(result, kwargs=kwargs or {})


def validate_fixture_extraction(tool_name: str, result: dict[str, Any]) -> list[str]:
    """Post-PASS checks that fixture IDs needed by downstream tools were extracted."""
    errors: list[str] = []
    if tool_name == "get_today_workout":
        sid = _first_value(result, "sessionId", "SessionId")
        scheduled = _first_value(result, "hasWorkoutScheduledToday", "HasWorkoutScheduledToday")
        if not sid and scheduled is not True:
            errors.append("get_today_workout: PASS but sessionId not present and no workout scheduled")
    elif tool_name == "get_active_roadmap":
        rid = _first_value(result, "id", "Id")
        if not rid:
            errors.append("get_active_roadmap: PASS but id not present in response")
    return errors
