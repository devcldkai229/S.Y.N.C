"""Batch audit runner — gọi AI thật qua POST /ai/chat, export kết quả ra file."""

from __future__ import annotations

import argparse
import json
import os
import statistics
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

import httpx

from tests.chat_batteries import BATTERIES, EXPECTED_INTENT, EXPECTED_INTENT_BY_ID

# Fallback khớp IamSeedData.cs khi không có iam_users_seed_data.json
_FALLBACK_DEMO_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
_FALLBACK_TIER = "Premium"
_FALLBACK_PERSONA = "FriendlyBuddy"
_FALLBACK_EMAIL = "demo@sync.local"

DEFAULT_BASE_URL = "http://localhost:8088"
DEFAULT_OUT_DIR = "tests/chat_runs"
DEFAULT_TOOL_RESULT_MAX_CHARS = 2000
REQUEST_TIMEOUT_S = 60.0


def _log(msg: str) -> None:
    """Print to console without crashing on Windows cp1252."""
    encoding = getattr(sys.stdout, "encoding", None) or "utf-8"
    try:
        print(msg)
    except UnicodeEncodeError:
        safe = msg.encode(encoding, errors="replace").decode(encoding, errors="replace")
        print(safe)


@dataclass
class TurnResult:
    id: str | int
    question: str
    expected: str
    intent: str | None = None
    tier: str | None = None
    tools: list[str] = field(default_factory=list)
    tool_results: list[dict[str, Any]] = field(default_factory=list)
    requires_confirmation: bool = False
    pending_action: dict[str, Any] | None = None
    handoff: dict[str, Any] | None = None
    first_token_ms: int | None = None
    total_ms: int | None = None
    answer: str = ""
    status: str = "OK"
    error: str | None = None
    session_id: str = ""
    session_group: str | None = None


def _repo_root() -> Path:
    here = Path(__file__).resolve().parent
    for parent in [here, *here.parents]:
        if (parent / "pyproject.toml").exists() and (parent / "app").is_dir():
            return parent.parent if parent.name == "sync-agent-service" else parent
    return here.parent


def _find_seed_json() -> Path | None:
  candidates = [
      _repo_root().parent / "iam_users_seed_data.json",
      _repo_root() / "iam_users_seed_data.json",
  ]
  for path in candidates:
      if path.is_file():
          return path
  return None


def _load_demo_from_seed(path: Path) -> tuple[str, str, str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    users = data if isinstance(data, list) else data.get("users") or data.get("Users") or []
    for user in users:
        email = (user.get("Email") or user.get("email") or "").lower()
        if email == _FALLBACK_EMAIL:
            uid = user.get("Id") or user.get("id") or _FALLBACK_DEMO_ID
            tier = user.get("SubscriptionTier") or user.get("tier") or _FALLBACK_TIER
            persona = (
                user.get("AgentPersona")
                or user.get("persona")
                or _FALLBACK_PERSONA
            )
            return str(uid), str(tier), str(persona)
    raise ValueError(f"Không tìm thấy {_FALLBACK_EMAIL} trong {path}")


def resolve_demo_identity() -> tuple[str, str, str]:
    seed = _find_seed_json()
    if seed is not None:
        _log(f"[auth] Loaded demo user from {seed}")
        return _load_demo_from_seed(seed)
    _log("[auth] iam_users_seed_data.json missing — using IamSeedData fallback demo id")
    return _FALLBACK_DEMO_ID, _FALLBACK_TIER, _FALLBACK_PERSONA


def mint_demo_jwt() -> str:
    env_token = os.environ.get("DEMO_JWT", "").strip()
    if env_token:
        _log("[auth] Using DEMO_JWT from environment")
        return env_token

    from app.config import get_settings

    demo_id, tier, persona = resolve_demo_identity()
    settings = get_settings()
    now = int(time.time())
    claims = {
        "sub": demo_id,
        "tier": tier,
        "persona": persona,
        "iss": settings.jwt_issuer,
        "aud": settings.jwt_audience,
        "iat": now,
        "exp": now + 3600,
    }
    import jwt

    return jwt.encode(claims, settings.jwt_signing_key, algorithm="HS256")


def check_health(base_url: str) -> None:
    url = f"{base_url.rstrip('/')}/healthz"
    try:
        with httpx.Client(timeout=10.0) as client:
            r = client.get(url)
            if r.status_code != 200:
                _log(f"[health] {url} -> HTTP {r.status_code}")
                _print_service_guide()
                sys.exit(1)
    except httpx.RequestError as exc:
        _log(f"[health] Cannot connect to {url}: {exc}")
        _print_service_guide()
        sys.exit(1)
    _log(f"[health] OK - {url}")


def _print_service_guide() -> None:
    _log(
        "\nCần bật stack trước khi chạy audit:\n"
        "  1. Docker: cd infra/docker && docker compose up -d\n"
        "  2. .NET: .\\core\\SyncPlatform\\scripts\\run-all.ps1\n"
        "  3. AI:   cd ai/sync-agent-service && uvicorn app.api.main:app --port 8088\n"
        "  4. LLM keys trong ai/sync-agent-service/.env (OPENAI_API_KEY)\n"
    )


def _parse_sse_block(event_name: str | None, data_lines: list[str]) -> dict[str, Any]:
    data = "\n".join(data_lines)
    ev_type = event_name or "message"
    out: dict[str, Any] = {"type": ev_type, "data": data}
    if ev_type in ("final", "message") and data.strip().startswith("{"):
        try:
            payload = json.loads(data)
            if isinstance(payload, dict):
                out["json"] = payload
        except json.JSONDecodeError:
            pass
    return out


def _consume_sse_stream(
    response: httpx.Response,
    started_at: float,
) -> tuple[str, dict[str, Any]]:
    tokens: list[str] = []
    final_text: str | None = None
    meta: dict[str, Any] = {
        "intent": None,
        "tier": None,
        "tools": [],
        "tool_results": [],
        "requires_confirmation": False,
        "pending_action": None,
        "handoff": None,
    }
    first_token_ms: int | None = None

    event_name: str | None = None
    data_lines: list[str] = []

    def _flush_block() -> None:
        nonlocal event_name, data_lines, first_token_ms, final_text
        if not data_lines and event_name is None:
            return
        block = _parse_sse_block(event_name, data_lines)
        ev_type = block["type"]
        data = block["data"]
        payload = block.get("json")

        if ev_type == "token" and data:
            if first_token_ms is None:
                first_token_ms = int((time.perf_counter() - started_at) * 1000)
            tokens.append(data)
        elif payload and (payload.get("type") == "final" or "text" in payload):
            meta["intent"] = payload.get("intent") or meta["intent"]
            meta["tier"] = payload.get("tier") or meta["tier"]
            tools = payload.get("tools")
            if isinstance(tools, list):
                meta["tools"] = [str(t) for t in tools]
            tool_results = payload.get("tool_results")
            if isinstance(tool_results, list):
                meta["tool_results"] = tool_results
            if payload.get("requires_confirmation"):
                meta["requires_confirmation"] = True
            text = payload.get("text")
            if isinstance(text, str) and text.strip():
                final_text = text.strip()
            if isinstance(text, str) and text.strip() and not tokens:
                tokens.append(text)
        elif ev_type == "confirm":
            meta["requires_confirmation"] = True
        elif ev_type == "pending_action" and data.strip().startswith("{"):
            try:
                meta["pending_action"] = json.loads(data)
            except json.JSONDecodeError:
                meta["pending_action"] = {"raw": data}
        elif ev_type == "handoff" and data.strip().startswith("{"):
            try:
                meta["handoff"] = json.loads(data)
            except json.JSONDecodeError:
                meta["handoff"] = {"raw": data}

        event_name = None
        data_lines = []

    for raw_line in response.iter_lines():
        line = raw_line.rstrip("\r")
        if line == "":
            _flush_block()
            continue
        if line.startswith(":"):
            continue
        if line.startswith("event:"):
            event_name = line[6:].strip()
        elif line.startswith("data:"):
            data_lines.append(line[5:].lstrip())

    _flush_block()

    answer = (final_text or "".join(tokens)).strip()
    meta["first_token_ms"] = first_token_ms
    return answer, meta


def run_turn(
    *,
    base_url: str,
    token: str,
    question: str,
    session_id: str,
    item_id: str | int,
    expected: str,
) -> TurnResult:
    url = f"{base_url.rstrip('/')}/ai/chat"
    result = TurnResult(
        id=item_id,
        question=question,
        expected=expected,
        session_id=session_id,
    )
    started = time.perf_counter()
    try:
        with httpx.Client(timeout=REQUEST_TIMEOUT_S) as client:
            with client.stream(
                "POST",
                url,
                headers={
                    "Authorization": f"Bearer {token}",
                    "Accept": "text/event-stream",
                    "Content-Type": "application/json",
                },
                json={"message": question, "session_id": session_id, "locale": "vi"},
            ) as response:
                if response.status_code >= 400:
                    body = response.read().decode("utf-8", errors="replace")
                    result.status = "ERROR"
                    result.error = f"HTTP {response.status_code}: {body[:500]}"
                    result.total_ms = int((time.perf_counter() - started) * 1000)
                    return result

                answer, meta = _consume_sse_stream(response, started)
                result.answer = answer
                result.intent = meta.get("intent")
                result.tier = meta.get("tier")
                result.tools = meta.get("tools") or []
                result.tool_results = meta.get("tool_results") or []
                result.requires_confirmation = bool(meta.get("requires_confirmation"))
                result.pending_action = meta.get("pending_action")
                result.handoff = meta.get("handoff")
                result.first_token_ms = meta.get("first_token_ms")
                result.total_ms = int((time.perf_counter() - started) * 1000)
                if not answer and result.status == "OK":
                    result.status = "ERROR"
                    result.error = "Không nhận được token/final text từ SSE"
    except httpx.TimeoutException:
        result.status = "ERROR"
        result.error = f"Timeout sau {int(REQUEST_TIMEOUT_S)}s"
        result.total_ms = int((time.perf_counter() - started) * 1000)
    except httpx.RequestError as exc:
        result.status = "ERROR"
        result.error = str(exc)
        result.total_ms = int((time.perf_counter() - started) * 1000)
    except Exception as exc:  # pragma: no cover
        result.status = "ERROR"
        result.error = f"{type(exc).__name__}: {exc}"
        result.total_ms = int((time.perf_counter() - started) * 1000)

    return result


def _session_id_for_item(category: str, item: dict[str, Any], ts: str, sessions: dict[str, str]) -> str:
    group = item.get("session_group")
    if group:
        key = f"{category}-{group}"
        if key not in sessions:
            sessions[key] = f"audit-{category}-{group}-{ts}"
        return sessions[key]
    return f"audit-{category}-{ts}"


def _expected_intent(category: str, item_id: str | int) -> str | None:
    if item_id in EXPECTED_INTENT_BY_ID:
        return EXPECTED_INTENT_BY_ID[item_id]
    return EXPECTED_INTENT.get(category)


def _format_ms(ms: int | None) -> str:
    if ms is None:
        return "n/a"
    if ms >= 1000:
        return f"{ms / 1000:.1f}s"
    return f"{ms}ms"


def _format_tools(tools: list[str]) -> str:
    if not tools:
        return "[]"
    return "[" + ", ".join(tools) + "]"


def _truncate_json_text(text: str, max_chars: int) -> str:
    if max_chars <= 0 or len(text) <= max_chars:
        return text
    return text[:max_chars] + "… (truncated)"


def _format_tool_results(
    tool_results: list[dict[str, Any]],
    *,
    max_chars: int = DEFAULT_TOOL_RESULT_MAX_CHARS,
) -> list[str]:
    if not tool_results:
        return ["--- Kết quả tools ---", "(không gọi tool)"]
    lines = ["--- Kết quả tools ---"]
    for idx, entry in enumerate(tool_results, start=1):
        tool_name = entry.get("tool", "unknown")
        args = entry.get("args", {})
        result = entry.get("result")
        try:
            args_text = json.dumps(args, ensure_ascii=False, default=str)
        except TypeError:
            args_text = str(args)
        try:
            result_text = json.dumps(result, ensure_ascii=False, indent=2, default=str)
        except TypeError:
            result_text = str(result)
        lines.append(f"[{idx}] {tool_name}")
        lines.append(f"  args   : {_truncate_json_text(args_text, max_chars)}")
        lines.append(f"  result : {_truncate_json_text(result_text, max_chars)}")
    return lines


def _render_turn_block(
    category: str,
    turn: TurnResult,
    *,
    tool_result_max_chars: int = DEFAULT_TOOL_RESULT_MAX_CHARS,
) -> list[str]:
    lines = [
        (
            f"[#{turn.id}] intent={turn.intent or 'n/a'} | tier={turn.tier or 'n/a'} | "
            f"tools={_format_tools(turn.tools)} | "
            f"first_token={_format_ms(turn.first_token_ms)} | "
            f"total={_format_ms(turn.total_ms)} | "
            f"confirm={str(turn.requires_confirmation).lower()}"
        ),
        f"Câu hỏi : {turn.question}",
        f"Kỳ vọng : {turn.expected}",
    ]
    if turn.session_group:
        lines.append(f"session   : {turn.session_group} (cùng phiên với turn trước)")
    expected_intent = _expected_intent(category, turn.id)
    if expected_intent and turn.intent and turn.intent != expected_intent:
        lines.append(
            f"⚠️ intent lệch: kỳ vọng={expected_intent} thực={turn.intent}"
        )
    if turn.status == "ERROR":
        lines.append(f"STATUS  : ERROR — {turn.error or 'unknown'}")
    if turn.pending_action:
        lines.append(f"pending : {json.dumps(turn.pending_action, ensure_ascii=False)}")
    if turn.handoff:
        lines.append(f"handoff : {json.dumps(turn.handoff, ensure_ascii=False)}")
    lines.extend(_format_tool_results(turn.tool_results, max_chars=tool_result_max_chars))
    lines.extend(
        [
            "--- Trả lời AI ---",
            turn.answer if turn.answer else "(trống)",
            "=" * 72,
            "",
        ]
    )
    return lines


def _summary_lines(results: list[TurnResult]) -> list[str]:
    total = len(results)
    errors = sum(1 for r in results if r.status == "ERROR")
    intent_counts: dict[str, int] = {}
    latencies = [r.total_ms for r in results if r.total_ms is not None and r.status == "OK"]

    for r in results:
        key = r.intent or "n/a"
        intent_counts[key] = intent_counts.get(key, 0) + 1

    lines = [
        "",
        "=" * 72,
        "TÓM TẮT",
        f"  Tổng câu     : {total}",
        f"  ERROR        : {errors}",
        "  Intent phân bố:",
    ]
    for intent, count in sorted(intent_counts.items()):
        lines.append(f"    - {intent}: {count}")

    if latencies:
        latencies_sorted = sorted(latencies)
        median = int(statistics.median(latencies_sorted))
        p95_idx = max(0, int(len(latencies_sorted) * 0.95) - 1)
        p95 = latencies_sorted[p95_idx]
        lines.append(f"  Latency median: {_format_ms(median)}")
        lines.append(f"  Latency p95    : {_format_ms(p95)}")
    else:
        lines.append("  Latency        : n/a (không có turn OK)")

    lines.append("=" * 72)
    return lines


def _turn_to_json(turn: TurnResult) -> dict[str, Any]:
    return {
        "id": turn.id,
        "question": turn.question,
        "expected": turn.expected,
        "intent": turn.intent,
        "tier": turn.tier,
        "tools": turn.tools,
        "tool_results": turn.tool_results,
        "requires_confirmation": turn.requires_confirmation,
        "pending_action": turn.pending_action,
        "handoff": turn.handoff,
        "first_token_ms": turn.first_token_ms,
        "total_ms": turn.total_ms,
        "answer": turn.answer,
        "status": turn.status,
        "error": turn.error,
        "session_id": turn.session_id,
        "session_group": turn.session_group,
    }


def run_category(
    category: str,
    *,
    base_url: str,
    token: str,
    out_dir: Path,
    ts: str,
    tool_result_max_chars: int = DEFAULT_TOOL_RESULT_MAX_CHARS,
) -> list[TurnResult]:
    items = BATTERIES[category]
    sessions: dict[str, str] = {}
    results: list[TurnResult] = []

    _log(f"\n=== Category: {category} ({len(items)} questions) ===")

    for item in items:
        item_id = item["id"]
        question = item["q"]
        expected = item["expected"]
        session_id = _session_id_for_item(category, item, ts, sessions)

        _log(f"  -> [#{item_id}] {question[:60]}{'...' if len(question) > 60 else ''}")
        turn = run_turn(
            base_url=base_url,
            token=token,
            question=question,
            session_id=session_id,
            item_id=item_id,
            expected=expected,
        )
        turn.session_group = item.get("session_group")
        turn.session_id = session_id
        results.append(turn)
        status_icon = "OK" if turn.status == "OK" else "ERR"
        _log(
            f"     [{status_icon}] intent={turn.intent or '-'} "
            f"total={_format_ms(turn.total_ms)} chars~{len(turn.answer)}"
        )

    out_dir.mkdir(parents=True, exist_ok=True)
    txt_path = out_dir / f"audit_{category}_{ts}.txt"
    json_path = out_dir / f"audit_{category}_{ts}.json"

    txt_lines = [
        f"CYN AI Chat Audit — {category}",
        f"Thời gian : {ts}",
        f"Base URL  : {base_url}",
        "",
    ]
    for turn in results:
        txt_lines.extend(
            _render_turn_block(category, turn, tool_result_max_chars=tool_result_max_chars)
        )
    txt_lines.extend(_summary_lines(results))
    txt_path.write_text("\n".join(txt_lines), encoding="utf-8")

    json_path.write_text(
        json.dumps([_turn_to_json(t) for t in results], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    _log(f"  Wrote: {txt_path}")
    _log(f"  Wrote: {json_path}")
    return results


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Batch audit CYN AI chat by category (live /ai/chat, export files).",
    )
    parser.add_argument("--all", action="store_true", help="Run all categories")
    parser.add_argument(
        "--base-url",
        default=DEFAULT_BASE_URL,
        help=f"AI service base URL (default {DEFAULT_BASE_URL})",
    )
    parser.add_argument(
        "--out-dir",
        default=DEFAULT_OUT_DIR,
        help=f"Output directory (default {DEFAULT_OUT_DIR})",
    )
    parser.add_argument(
        "--tool-result-max-chars",
        type=int,
        default=DEFAULT_TOOL_RESULT_MAX_CHARS,
        help=f"Max chars per tool result in TXT export (default {DEFAULT_TOOL_RESULT_MAX_CHARS}, 0=unlimited)",
    )
    for category in BATTERIES:
        parser.add_argument(
            f"--{category}",
            action="store_true",
            dest=f"cat_{category}",
            help=f"Run {category} battery",
        )
    return parser


def _selected_categories(args: argparse.Namespace) -> list[str]:
    if args.all:
        return list(BATTERIES.keys())
    selected = [cat for cat in BATTERIES if getattr(args, f"cat_{cat}", False)]
    return selected


def main() -> None:
    parser = _build_parser()
    args = parser.parse_args()
    categories = _selected_categories(args)

    if not categories:
        parser.error(
            "Chọn ít nhất một category (--Coach, --Workout, ...) hoặc --all"
        )

    base_url = args.base_url.rstrip("/")
    out_dir = Path(args.out_dir)
    ts = datetime.now().strftime("%Y%m%d-%H%M")

    token = mint_demo_jwt()
    check_health(base_url)

    _log(f"[run] Categories: {', '.join(categories)}")
    _log(f"[run] Output dir: {out_dir.resolve()}")

    for category in categories:
        run_category(
            category,
            base_url=base_url,
            token=token,
            out_dir=out_dir,
            ts=ts,
            tool_result_max_chars=args.tool_result_max_chars,
        )

    _log("\n[done] Audit complete.")


if __name__ == "__main__":
    main()
