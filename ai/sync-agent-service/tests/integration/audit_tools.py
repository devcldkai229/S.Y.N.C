"""
Audit every tool in TOOL_REGISTRY — real impls via build_impls, no LLM.

Run:
  python -m tests.integration.audit_tools              # connectivity smoke
  python -m tests.integration.audit_tools --assert-contracts  # + demo seed contracts

Contract pytest (stricter, read-after-write):
  set RUN_INTEGRATION=1
  pytest tests/integration/test_tool_contracts.py -v

Not audited: propose_order (commerce agent only), create_order (dotnet adapter, not in registry).
"""
from __future__ import annotations

import argparse
import asyncio
import re
import sys
import time
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from app.config import get_settings
from app.tools.catalog import AGENT_TOOLS, TOOL_REGISTRY
from tests.integration.demo_contracts import validate_contract, validate_fixture_extraction, EXPECT_TODAY_SESSION_ID
from tests.integration.integration_harness import (
    SEED_ALT_EXERCISE_ID,
    SEED_PARTNER_ID,
    build_tool_impls,
    make_context,
    patch_safe_tool_call,
    resolve_demo_user_id,
    restore_safe_tool_call,
)

STATUS_PASS = "PASS"
STATUS_FAIL = "FAIL"
STATUS_NOT_IMPL = "NOT_IMPLEMENTED"
STATUS_CONN = "CONN_ERROR"
STATUS_SKIPPED = "SKIPPED"
STATUS_DRYRUN = "DRYRUN"

SYMBOL = {
    STATUS_PASS: "[+]",
    STATUS_FAIL: "[X]",
    STATUS_NOT_IMPL: "[?]",
    STATUS_CONN: "[~]",
    STATUS_SKIPPED: "[-]",
    STATUS_DRYRUN: "[=]",
}

TIER_A_BOOTSTRAP = frozenset({
    "get_active_roadmap", "get_today_workout", "search_exercises", "search_food",
    "search_partners", "list_vouchers", "check_wallet",
})

TIER_B_DEPENDS = frozenset({
    "get_roadmap_sessions", "get_exercise_detail", "get_exercise_media", "get_menu",
    "get_food_by_barcode", "adjust_intensity", "substitute_exercise", "track_order",
    "apply_voucher", "update_roadmap",
})

TIER_C_WRITE_CHAIN = frozenset({
    "log_workout_execution", "log_set", "schedule_roadmap_session",
})

ORDER_FIXTURE_TOOLS = frozenset({"track_order", "reorder", "apply_voucher"})

SECRET_PATTERNS = re.compile(
    r"(api[_-]?key|secret|password|token|authorization)", re.I,
)


@dataclass
class FixtureStore:
    roadmap_id: str = ""
    session_id: str = ""
    execution_id: str = ""
    exercise_id: str = ""
    alt_exercise_id: str = ""
    partner_id: str = ""
    food_item_id: str = ""
    barcode: str = ""
    voucher_code: str = ""
    order_id: str = ""
    order_draft_id: str = ""

    def as_dict(self) -> dict[str, str]:
        return {k: v for k, v in self.__dict__.items() if v}


@dataclass
class AuditResult:
    name: str
    agents: list[str]
    tool_type: str
    status: str
    latency_ms: int
    message: str = ""
    contract_errors: list[str] = field(default_factory=list)


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


def _first_item_list(result: dict[str, Any]) -> dict[str, Any] | None:
    for key in ("items", "Items", "data", "Data"):
        raw = result.get(key)
        if isinstance(raw, list) and raw and isinstance(raw[0], dict):
            return raw[0]
    if isinstance(result.get("value"), list) and result["value"]:
        first = result["value"][0]
        return first if isinstance(first, dict) else None
    return None


def _extract_id(result: dict[str, Any], *keys: str) -> str:
    val = _first_value(result, *keys)
    if val is not None:
        return str(val)
    item = _first_item_list(result)
    if item:
        nested = _first_value(item, *keys, "id", "Id")
        if nested is not None:
            return str(nested)
    return ""


def update_fixtures(store: FixtureStore, tool_name: str, result: dict[str, Any]) -> None:
    if tool_name == "get_active_roadmap":
        store.roadmap_id = _extract_id(result, "id", "Id") or store.roadmap_id
    elif tool_name == "get_today_workout":
        store.session_id = _extract_id(result, "sessionId", "SessionId") or store.session_id
        if not store.session_id:
            scheduled = _first_value(result, "hasWorkoutScheduledToday", "HasWorkoutScheduledToday")
            if scheduled is True:
                store.session_id = EXPECT_TODAY_SESSION_ID
    elif tool_name == "search_exercises":
        item = _first_item_list(result)
        if item:
            eid = _extract_id(item, "id", "Id")
            if eid:
                if not store.exercise_id:
                    store.exercise_id = eid
                elif eid != store.exercise_id:
                    store.alt_exercise_id = eid
    elif tool_name == "search_food":
        item = _first_item_list(result)
        if item:
            store.food_item_id = _extract_id(item, "id", "Id") or store.food_item_id
            bc = _first_value(item, "barcode", "Barcode")
            if bc:
                store.barcode = str(bc)
    elif tool_name == "search_partners":
        pid = _extract_id(result, "id", "Id", "partnerId", "PartnerId")
        if pid:
            store.partner_id = pid
    elif tool_name == "list_vouchers":
        item = _first_item_list(result)
        if item:
            code = _first_value(item, "couponCode", "CouponCode", "code", "Code", "voucherCode")
            if code:
                store.voucher_code = str(code)
        if not store.voucher_code:
            store.voucher_code = "DEMO10K"
    elif tool_name == "log_workout_execution":
        store.execution_id = (
            _extract_id(result, "id", "Id", "executionLogId", "ExecutionLogId")
            or store.execution_id
        )


def execution_order(tool_names: list[str]) -> list[str]:
    names = set(tool_names)
    tier_a = sorted(n for n in names if n in TIER_A_BOOTSTRAP)
    tier_b = sorted(n for n in names if n in TIER_B_DEPENDS)
    tier_c = sorted(n for n in names if n in TIER_C_WRITE_CHAIN)
    rest = sorted(n for n in names if n not in TIER_A_BOOTSTRAP | TIER_B_DEPENDS | TIER_C_WRITE_CHAIN)
    ordered: list[str] = []
    seen: set[str] = set()
    for group in (tier_a, rest, tier_b, tier_c):
        for n in group:
            if n not in seen:
                ordered.append(n)
                seen.add(n)
    return ordered


def agents_for_tool(name: str) -> list[str]:
    defn = TOOL_REGISTRY.get(name)
    if defn:
        return sorted(defn.agents)
    for agent, tools in AGENT_TOOLS.items():
        if name in tools:
            return [agent]
    return ["(unassigned)"]


def _base_sample_args(tool_name: str) -> dict[str, Any]:
    now = datetime.now(timezone.utc)
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    ts = now.strftime("%Y-%m-%dT%H:%M:%SZ")

    samples: dict[str, dict[str, Any]] = {
        "search_food": {"query": "ức gà", "limit": 3},
        "search_exercises": {"query": "squat", "limit": 3},
        "log_water": {"amount_ml": 250},
        "log_meal": {
            "meal_type": "Snack",
            "items": [{"foodName": "audit snack", "quantityGram": 50}],
            "notes": "tool audit",
        },
        "log_mood_checkin": {"mood": "Calm", "note": "audit"},
        "remember_user_fact": {"fact": f"audit-{ts}"[:200]},
        "recall_user_memory": {"query": "thích", "k": 3},
        "handoff": {"target_agent": "coach", "reason": "audit"},
        "send_notification": {
            "title": "Audit",
            "body": "Tool audit ping",
            "deep_link": "",
        },
        "escalate_to_human": {"reason": "audit drill", "severity": "low"},
        "recommend_partner_meals": {"goal": "LoseFat", "max_price": 120_000},
        "search_partners": {"query": "kitchen"},
        "recommend_affiliate_products": {"category": "supplement"},
        "get_progress_trends": {"metric": "calories", "days": 3},
        "detect_plateau": {"metric": "calories"},
        "request_replan": {"reason": "audit smoke"},
        "adjust_intensity": {"factor": 0.95},
        "substitute_exercise": {"reason": "audit substitute"},
        "log_workout_execution": {
            "duration_min": 20,
            "perceived_difficulty": "easy",
            "energy_before": 6,
            "energy_after": 5,
        },
        "log_set": {"set_number": 1, "actual_reps": 10, "weight_kg": 0, "rir": 2},
        "estimate_meal_from_photo": {"image_url": "https://example.com/meal.jpg"},
        "suggest_meal_plan": {"meals_per_day": 3},
        "topup_wallet": {"amount": 10_000, "method": "VietQR"},
        "reorder": {"previous_order_id": ""},
        "apply_voucher": {"voucher_code": "DEMO10K", "order_draft_id": ""},
        "track_order": {"order_id": ""},
        "update_roadmap": {"current_phase": "Audit"},
        "schedule_roadmap_session": {
            "scheduled_date": f"{tomorrow}T07:00:00+07:00",
            "scheduled_time": "07:00",
            "session_title": "Audit Session",
            "session_type": "Strength",
            "estimated_duration_minutes": 30,
            "execution_blocks": [],
        },
    }
    return dict(samples.get(tool_name, {}))


def _skip_reason(tool_name: str, store: FixtureStore, include_financial: bool) -> str | None:
    defn = TOOL_REGISTRY.get(tool_name)
    if defn and defn.tool_type == "financial" and not include_financial:
        return None  # handled as DRYRUN

    if tool_name in ORDER_FIXTURE_TOOLS:
        if tool_name == "apply_voucher" and include_financial:
            if not store.order_draft_id:
                return "no order fixture in seed"
        elif tool_name in ("track_order", "reorder"):
            if not store.order_id:
                return "no order fixture in seed"
        elif tool_name == "apply_voucher":
            return None

    if tool_name == "get_food_by_barcode" and not store.barcode:
        return "no barcode in seed or search_food result"

    if tool_name == "get_roadmap_sessions" and not store.roadmap_id:
        return "missing roadmap_id from get_active_roadmap"

    if tool_name == "update_roadmap" and not store.roadmap_id:
        return "missing roadmap_id"

    if tool_name in ("get_exercise_detail", "get_exercise_media") and not store.exercise_id:
        return "missing exercise_id from search_exercises"

    if tool_name == "get_menu" and not (store.partner_id or SEED_PARTNER_ID):
        return "missing partner_id"

    if tool_name == "adjust_intensity" and not store.session_id:
        return "missing session_id from get_today_workout"

    if tool_name == "substitute_exercise":
        if not store.session_id:
            return "missing session_id"
        if not store.exercise_id and not store.alt_exercise_id:
            return "missing exercise_id"

    if tool_name == "log_workout_execution" and not store.session_id:
        return "missing session_id"

    if tool_name == "log_set":
        if not store.execution_id:
            return "missing execution_id from log_workout_execution"
        if not store.exercise_id:
            return "missing exercise_id"

    if tool_name == "schedule_roadmap_session":
        if not store.roadmap_id:
            return "missing roadmap_id"
        if not store.exercise_id:
            return "missing exercise_id for execution_blocks"

    return None


def resolve_kwargs(tool_name: str, store: FixtureStore) -> dict[str, Any]:
    kwargs = _base_sample_args(tool_name)

    if tool_name == "get_roadmap_sessions":
        kwargs["roadmap_id"] = store.roadmap_id
    elif tool_name == "update_roadmap":
        kwargs["roadmap_id"] = store.roadmap_id
    elif tool_name == "get_exercise_detail":
        kwargs["exercise_id"] = store.exercise_id
    elif tool_name == "get_exercise_media":
        kwargs["exercise_id"] = store.exercise_id
    elif tool_name == "get_menu":
        kwargs["partner_id"] = store.partner_id or SEED_PARTNER_ID
    elif tool_name == "get_food_by_barcode":
        kwargs["barcode"] = store.barcode
    elif tool_name == "adjust_intensity":
        kwargs["session_id"] = store.session_id
    elif tool_name == "substitute_exercise":
        kwargs["session_id"] = store.session_id
        kwargs["exercise_id"] = store.alt_exercise_id or SEED_ALT_EXERCISE_ID
    elif tool_name == "log_workout_execution":
        kwargs["session_id"] = store.session_id
    elif tool_name == "log_set":
        kwargs["execution_id"] = store.execution_id
        kwargs["exercise_id"] = store.exercise_id
    elif tool_name == "track_order":
        kwargs["order_id"] = store.order_id
    elif tool_name == "reorder":
        kwargs["previous_order_id"] = store.order_id
    elif tool_name == "apply_voucher":
        kwargs["voucher_code"] = store.voucher_code or "DEMO10K"
        kwargs["order_draft_id"] = store.order_draft_id
    elif tool_name == "schedule_roadmap_session":
        kwargs["roadmap_id"] = store.roadmap_id
        ex = store.exercise_id
        kwargs["execution_blocks"] = [{
            "order": 1,
            "exerciseId": ex,
            "exerciseName": "Audit Exercise",
            "targetSets": 3,
            "targetReps": 10,
            "targetWeightKg": 0,
            "restSeconds": 60,
            "tempo": "2010",
        }]
    elif tool_name == "log_meal" and store.food_item_id:
        kwargs["items"] = [{"foodItemId": store.food_item_id, "quantityGram": 50}]

    return kwargs


def classify_error_message(msg: str) -> str:
    lower = msg.lower()
    if any(x in lower for x in (
        "connection refused", "connect error", "connecttimeout",
        "name or service not known", "all connection attempts failed",
        "failed to establish", "connection reset", "network is unreachable",
        "retryerror",
    )):
        # Unwrap tenacity RetryError — often wraps ConnectError or HTTPStatusError
        if "404" in lower or "not found" in lower:
            return STATUS_NOT_IMPL
        if re.search(r"\b5\d{2}\b", lower):
            return STATUS_FAIL
        if any(x in lower for x in ("connection", "refused", "unreachable", "failed to establish")):
            return STATUS_CONN
    if any(x in lower for x in ("404", "501", "not found", "does not exist")):
        return STATUS_NOT_IMPL
    if re.search(r"\b5\d{2}\b", msg):
        return STATUS_FAIL
    return STATUS_FAIL


def classify_result(tool_name: str, result: Any, error_msg: str | None) -> tuple[str, str]:
    if error_msg:
        if "timeout" in error_msg.lower():
            return STATUS_FAIL, error_msg[:120]
        return classify_error_message(error_msg), error_msg[:120]

    if not isinstance(result, dict):
        return STATUS_FAIL, "result is not a dict"

    if tool_name == "estimate_meal_from_photo":
        err = result.get("error")
        if err == "vision_disabled":
            return STATUS_SKIPPED, str(err)

    if "error" in result and result["error"]:
        msg = str(result["error"])
        return classify_error_message(msg), msg[:120]

    return STATUS_PASS, ""


def sanitize_note(text: str) -> str:
    if SECRET_PATTERNS.search(text):
        return "[redacted]"
    return text[:120]


async def audit_tool(
    name: str,
    impl: Any,
    store: FixtureStore,
    *,
    timeout_sec: float,
    include_financial: bool,
    assert_contracts: bool = False,
) -> AuditResult:
    defn = TOOL_REGISTRY[name]
    ag = agents_for_tool(name)

    if defn.tool_type == "financial" and not include_financial:
        return AuditResult(
            name, ag, defn.tool_type, STATUS_DRYRUN, 0,
            "use --include-financial to run",
        )

    skip = _skip_reason(name, store, include_financial)
    if skip:
        return AuditResult(name, ag, defn.tool_type, STATUS_SKIPPED, 0, skip)

    kwargs = resolve_kwargs(name, store)
    t0 = time.perf_counter()
    try:
        result = await asyncio.wait_for(impl(**kwargs), timeout=timeout_sec)
        latency = int((time.perf_counter() - t0) * 1000)
        status, msg = classify_result(name, result, None)
        contract_errors: list[str] = []
        if status == STATUS_PASS and isinstance(result, dict):
            if assert_contracts:
                contract_errors = validate_contract(name, result, kwargs=kwargs)
                contract_errors.extend(validate_fixture_extraction(name, result))
                if contract_errors:
                    status = STATUS_FAIL
                    msg = "; ".join(contract_errors)[:120]
            if status == STATUS_PASS:
                update_fixtures(store, name, result)
        return AuditResult(
            name, ag, defn.tool_type, status, latency, msg, contract_errors,
        )
    except asyncio.TimeoutError:
        latency = int((time.perf_counter() - t0) * 1000)
        return AuditResult(name, ag, defn.tool_type, STATUS_FAIL, latency, "timeout")
    except Exception as exc:
        latency = int((time.perf_counter() - t0) * 1000)
        msg = str(exc)
        status = classify_error_message(msg)
        return AuditResult(name, ag, defn.tool_type, status, latency, msg[:120])


async def run_audit(
    *,
    timeout_sec: float,
    include_financial: bool,
    assert_contracts: bool = False,
) -> list[AuditResult]:
    patch_safe_tool_call()
    try:
        return await _run_audit_inner(
            timeout_sec=timeout_sec,
            include_financial=include_financial,
            assert_contracts=assert_contracts,
        )
    finally:
        restore_safe_tool_call()


async def _run_audit_inner(
    *,
    timeout_sec: float,
    include_financial: bool,
    assert_contracts: bool = False,
) -> list[AuditResult]:
    demo_id, _source = resolve_demo_user_id()
    ctx = make_context(demo_id)
    all_names = sorted(TOOL_REGISTRY.keys())
    impls = build_tool_impls(ctx, all_names)
    store = FixtureStore(partner_id=SEED_PARTNER_ID)
    order = execution_order(all_names)
    results: list[AuditResult] = []
    results_by_name: dict[str, AuditResult] = {}

    for name in order:
        if name not in impls:
            defn = TOOL_REGISTRY[name]
            r = AuditResult(
                name, agents_for_tool(name), defn.tool_type,
                STATUS_SKIPPED, 0, "no impl",
            )
            results.append(r)
            results_by_name[name] = r
            continue
        r = await audit_tool(
            name, impls[name], store,
            timeout_sec=timeout_sec,
            include_financial=include_financial,
            assert_contracts=assert_contracts,
        )
        results.append(r)
        results_by_name[name] = r

    return results


def print_report(results: list[AuditResult], *, demo_id: str) -> None:
    settings = get_settings()
    print(f"\nSYNC Tool Audit | user={demo_id} | iam={settings.iam_base_url}")
    print("=" * 88)

    by_name = {r.name: r for r in results}
    printed: set[str] = set()

    for agent in ("coach", "nutrition", "workout", "commerce", "insight"):
        tools = AGENT_TOOLS.get(agent, [])
        if not tools:
            continue
        print(f"\n## Agent: {agent}")
        print(f"{'tool':<32} {'type':<10} {'status':<18} {'ms':>6}  note")
        print("-" * 88)
        for tool in tools:
            if tool not in by_name:
                continue
            r = by_name[tool]
            printed.add(tool)
            sym = SYMBOL.get(r.status, "?")
            note = sanitize_note(r.message)
            print(f"{r.name:<32} {r.tool_type:<10} {sym} {r.status:<14} {r.latency_ms:>6}  {note}")

    orphan = sorted(set(by_name) - printed)
    if orphan:
        print("\n## Other (registry only)")
        print(f"{'tool':<32} {'type':<10} {'status':<18} {'ms':>6}  note")
        print("-" * 88)
        for tool in orphan:
            r = by_name[tool]
            sym = SYMBOL.get(r.status, "?")
            print(f"{r.name:<32} {r.tool_type:<10} {sym} {r.status:<14} {r.latency_ms:>6}  {sanitize_note(r.message)}")

    counts: dict[str, int] = {}
    for r in results:
        counts[r.status] = counts.get(r.status, 0) + 1

    print("\n" + "=" * 88)
    print(
        f"Total: {len(results)} | "
        f"PASS={counts.get(STATUS_PASS, 0)} | "
        f"FAIL={counts.get(STATUS_FAIL, 0)} | "
        f"NOT_IMPL={counts.get(STATUS_NOT_IMPL, 0)} | "
        f"CONN_ERROR={counts.get(STATUS_CONN, 0)} | "
        f"SKIPPED={counts.get(STATUS_SKIPPED, 0)} | "
        f"DRYRUN={counts.get(STATUS_DRYRUN, 0)}"
    )


def write_json_report(results: list[AuditResult], path: Path) -> None:
    import json

    payload = [
        {
            "name": r.name,
            "agents": r.agents,
            "type": r.tool_type,
            "status": r.status,
            "latency_ms": r.latency_ms,
            "message": r.message,
            **({"contract_errors": r.contract_errors} if r.contract_errors else {}),
        }
        for r in results
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    default_json = Path(__file__).resolve().parent / "tool_audit_report.json"
    p = argparse.ArgumentParser(description="Audit all TOOL_REGISTRY impls (no LLM).")
    p.add_argument("--include-financial", action="store_true", help="Run financial tools for real")
    p.add_argument("--timeout", type=float, default=20.0, help="Per-tool timeout seconds")
    p.add_argument("--json-out", type=Path, default=default_json, help="JSON report path")
    p.add_argument(
        "--strict", action="store_true",
        help="Exit 1 on CONN_ERROR (services down) as well as FAIL",
    )
    p.add_argument(
        "--assert-contracts", action="store_true",
        help="FAIL when demo seed contract violations detected (read tools)",
    )
    return p.parse_args()


async def async_main() -> int:
    args = parse_args()
    demo_id, source = resolve_demo_user_id()
    print(f"Demo user: {demo_id} (from {source})", file=sys.stderr)

    results = await run_audit(
        timeout_sec=args.timeout,
        include_financial=args.include_financial,
        assert_contracts=args.assert_contracts,
    )
    print_report(results, demo_id=demo_id)
    write_json_report(results, args.json_out)
    print(f"\nReport: {args.json_out.resolve()}")

    fails = sum(1 for r in results if r.status == STATUS_FAIL)
    if fails:
        return 1
    if args.strict and any(r.status == STATUS_CONN for r in results):
        return 1
    return 0


def main() -> None:
    raise SystemExit(asyncio.run(async_main()))


if __name__ == "__main__":
    main()
