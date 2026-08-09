"""Guardrail nodes — first-class trong graph (IN/OUT) + spending gate.

Logic an toàn (PII/injection/content) đã tách sang `app/safety/` để tái dùng & test
độc lập. Node ở đây chỉ điều phối: gắn cờ, che dữ liệu, và cổng xác nhận chi tiêu.
"""
from __future__ import annotations

from typing import Any

from app.safety import check_output_safety, detect_injection, scrub_pii
from app.observability.flow_log import flow, flow_data
from app.state import SyncAgentState


def _last_user_text(state: SyncAgentState) -> str:
    msgs = state.get("messages", [])
    if not msgs:
        return ""
    c = getattr(msgs[-1], "content", "")
    return c if isinstance(c, str) else ""


def guardrail_in(state: SyncAgentState) -> dict[str, Any]:
    """Chạy trước supervisor. Không chặn cứng; gắn cờ để downstream xử lý."""
    flags = list(state.get("guardrail_flags", []))
    last = _last_user_text(state)

    if detect_injection(last):
        flags.append("prompt_injection_suspected")
        flow("Guardrail IN — nghi prompt injection", indent=3)

    cleaned, pii_flags = scrub_pii(last)
    flags.extend(pii_flags)
    if pii_flags:
        flow_data("Guardrail IN — PII đã che", pii_flags, indent=3)

    return {
        "guardrail_flags": flags,
        "tool_results": {**state.get("tool_results", {}), "_cleaned_input": cleaned},
    }


def guardrail_out(state: SyncAgentState) -> dict[str, Any]:
    """Chạy sau khi compose. Kiểm tra an toàn nội dung + spending gate."""
    flags = list(state.get("guardrail_flags", []))
    resp = state.get("final_response") or ""

    safe_resp, has_unsafe = check_output_safety(resp)
    if has_unsafe:
        flags.append("unsafe_health_advice")
        flow("Guardrail OUT — phát hiện lời khuyên sức khỏe không an toàn", indent=3)
    resp = safe_resp

    # Spending gate: hành động vượt hạn mức -> cần xác nhận (human-in-the-loop).
    requires_confirmation = bool(state.get("requires_confirmation"))

    # Write actions that still need HITL confirmation
    _WRITE_ACTION_TYPES = {
        "create_roadmap", "delete_roadmap", "reschedule_session",
        "enable_ai_reschedule",
        "upgrade_premium",
        "apply_adjustment",
        # Legacy pending cards (older sessions)
        "generate_week_plan", "plan_or_edit_workout",
    }
    pending = state.get("pending_actions", [])
    if pending:
        requires_confirmation = True
        for a in pending:
            if a.get("over_limit"):
                flags.append("spending_requires_confirmation")
                flow("Guardrail OUT — đơn vượt hạn mức → cần user xác nhận", indent=3)
            if a.get("type") in _WRITE_ACTION_TYPES:
                flags.append("write_action_requires_confirmation")
                flow(f"Guardrail OUT — write action '{a.get('type')}' → cần user xác nhận", indent=3)

    return {
        "final_response": resp,
        "guardrail_flags": flags,
        "requires_confirmation": requires_confirmation,
    }
