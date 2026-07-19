"""Post-agent routing: handoff loop vs end-of-turn guardrails."""
from __future__ import annotations

from typing import Literal

from app.state import SyncAgentState
from app.observability.flow_log import flow

_MAX_HANDOFFS_PER_TURN = 1


def route_after_agent(state: SyncAgentState) -> Literal["prepare_handoff", "guardrail_out"]:
    next_agent = state.get("next_agent")
    count = state.get("handoff_count") or 0
    if next_agent and count < _MAX_HANDOFFS_PER_TURN:
        return "prepare_handoff"
    return "guardrail_out"


async def prepare_handoff(state: SyncAgentState) -> dict:
    """Transfer control to another specialist without re-classifying user text."""
    target = state.get("next_agent") or "coach"
    reason = state.get("handoff_reason") or ""
    flow(f"Handoff — chuẩn bị chuyển sang [{target}] | lý do: {reason}", indent=3)
    return {
        "target_agent": target,
        "handoff_target": target,
        "handoff_count": (state.get("handoff_count") or 0) + 1,
        "next_agent": None,
        "handoff_reason": state.get("handoff_reason"),
        "intent_source": "handoff",
    }
