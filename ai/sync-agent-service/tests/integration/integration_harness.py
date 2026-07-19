"""Shared harness for integration tests and audit_tools."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any, Awaitable, Callable

import httpx

from app.config import get_settings
from app.tools import catalog as catalog_mod
from app.tools import context as tool_context
from app.tools.catalog import TOOL_REGISTRY, build_impls
from app.tools.context import ToolRunContext

from tests.integration.demo_contracts import DEMO_EMAIL, DEMO_USER_ID

ToolFn = Callable[..., Awaitable[dict[str, Any]]]

_orig_safe_tool_call = tool_context.safe_tool_call

SEED_PARTNER_ID = "a1000001-0000-0000-0000-000000000001"
SEED_ALT_EXERCISE_ID = "22222222-2222-2222-2222-222222222222"


async def _audit_safe_tool_call(fn: Any, *args: Any, **kwargs: Any) -> dict[str, Any]:
    return await _orig_safe_tool_call(fn, **kwargs)


def patch_safe_tool_call() -> None:
    tool_context.safe_tool_call = _audit_safe_tool_call
    catalog_mod.safe_tool_call = _audit_safe_tool_call


def restore_safe_tool_call() -> None:
    tool_context.safe_tool_call = _orig_safe_tool_call
    catalog_mod.safe_tool_call = _orig_safe_tool_call


def integration_requested() -> bool:
    return os.environ.get("RUN_INTEGRATION", "").strip().lower() in ("1", "true", "yes")


def _find_seed_json() -> Path | None:
    here = Path(__file__).resolve()
    for parent in [here.parent, *here.parents[:8]]:
        candidate = parent / "iam_users_seed_data.json"
        if candidate.is_file():
            return candidate
    return None


def _parse_user_id_from_json(path: Path) -> str | None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    users = data if isinstance(data, list) else data.get("users") or data.get("Users") or []
    if not isinstance(users, list):
        return None
    for user in users:
        if not isinstance(user, dict):
            continue
        email = user.get("email") or user.get("Email") or ""
        if str(email).lower() == DEMO_EMAIL:
            uid = user.get("id") or user.get("Id")
            return str(uid) if uid else None
    return None


def resolve_demo_user_id() -> tuple[str, str]:
    """Returns (user_id, source_label)."""
    seed_path = _find_seed_json()
    if seed_path:
        uid = _parse_user_id_from_json(seed_path)
        if uid:
            return uid, f"iam_users_seed_data.json ({seed_path})"

    env_uid = os.environ.get("DEMO_USER_ID", "").strip()
    if env_uid:
        return env_uid, "DEMO_USER_ID env"

    print(
        "iam_users_seed_data.json not found; using IamSeedData demo user",
        file=sys.stderr,
    )
    return DEMO_USER_ID, "IamSeedData.DemoUserId"


def make_context(demo_user_id: str | None = None) -> ToolRunContext:
    uid = demo_user_id or DEMO_USER_ID
    return ToolRunContext(
        user_id=uid,
        state={"user_id": uid, "user_snapshot": {"agentPersona": "FriendlyBuddy"}},
    )


def build_tool_impls(
    ctx: ToolRunContext,
    tool_names: list[str] | None = None,
) -> dict[str, ToolFn]:
    names = tool_names or sorted(TOOL_REGISTRY.keys())
    return build_impls(ctx, names)


async def invoke_tool(
    impls: dict[str, ToolFn],
    name: str,
    **kwargs: Any,
) -> dict[str, Any]:
    if name not in impls:
        raise KeyError(f"tool not in impls: {name}")
    result = await impls[name](**kwargs)
    if not isinstance(result, dict):
        return {"error": "result is not a dict", "value": result}
    return result


async def services_reachable() -> bool:
    """Quick ping to IAM gamification endpoint for demo user."""
    s = get_settings()
    url = f"{s.iam_base_url}/api/internal/gamification/{DEMO_USER_ID}"
    headers = {
        "X-Internal-Api-Key": s.internal_api_key,
        "X-User-Id": DEMO_USER_ID,
        "Accept": "application/json",
    }
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            response = await client.get(url, headers=headers)
            return response.status_code < 500
    except (httpx.HTTPError, OSError):
        return False
