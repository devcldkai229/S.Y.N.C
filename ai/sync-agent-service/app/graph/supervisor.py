"""Orchestrator / Supervisor node.

Phân loại intent + nạp IAM snapshot **song song** (asyncio.gather) để giảm latency
trước khi vào specialist agent.
"""
from __future__ import annotations

import asyncio
from time import perf_counter
from typing import Any

from app.config import ModelTier
from app.graph.context import load_context
from app.graph.intent import classify_intent
from app.graph.subscription_gating import (
    cap_model_tier_for_subscription,
    ensure_commerce_model_tier,
    normalize_tier,
)
from app.observability.flow_log import flow
from app.state import SyncAgentState


def _last_user_text(state: SyncAgentState) -> str:
    msgs = state.get("messages", [])
    if not msgs:
        return ""
    content = getattr(msgs[-1], "content", "")
    return content if isinstance(content, str) else ""


def _recent_context(state: SyncAgentState) -> str | None:
    """Lấy nội dung lượt assistant gần nhất làm bối cảnh cho classifier (giúp câu nối tiếp)."""
    msgs = state.get("messages", [])
    for m in reversed(msgs[:-1]):
        if getattr(m, "type", "") in ("ai", "assistant"):
            c = getattr(m, "content", "")
            if isinstance(c, str) and c:
                return c[:200]
    return None


def _routing_from_intent(result: Any, state: SyncAgentState) -> dict[str, Any]:
    tier = result.tier_for_reply()

    used = state.get("tokens_used", 0)
    budget = state.get("token_budget", 8000)
    if used > budget * 0.8 and tier == ModelTier.LARGE:
        tier = ModelTier.MID

    if "prompt_injection_suspected" in state.get("guardrail_flags", []):
        tier = ModelTier.SMALL

    subscription_tier = normalize_tier(
        state.get("subscription_tier")
        or (state.get("user_snapshot") or {}).get("subscriptionTier")
    )
    capped = cap_model_tier_for_subscription(subscription_tier, tier)
    if result.agent == "commerce":
        capped = ensure_commerce_model_tier(subscription_tier, capped)

    return {
        "locale": result.language,
        "intent": result.agent,
        "target_agent": result.agent,
        "model_tier": capped,
        "subscription_tier": subscription_tier,
        "intent_confidence": result.confidence,
        "intent_source": result.source,
        "intent_reason": result.reason,
    }


async def supervisor(state: SyncAgentState) -> dict[str, Any]:
    handoff_target = state.get("handoff_target")
    if handoff_target:
        tier = state.get("model_tier") or ModelTier.MID.value
        flow(f"Supervisor — handoff hop → agent={handoff_target} (bỏ qua phân loại LLM)", indent=3)
        return {
            "locale": state.get("locale", "vi"),
            "intent": handoff_target,
            "target_agent": handoff_target,
            "model_tier": tier,
            "intent_confidence": 1.0,
            "intent_source": "handoff",
            "handoff_target": None,
        }

    text = _last_user_text(state)
    recent = _recent_context(state)

    t0 = perf_counter()
    ctx_updates, result = await asyncio.gather(
        load_context(state),
        classify_intent(text, recent),
    )
    elapsed_ms = int((perf_counter() - t0) * 1000)
    flow(
        f"Supervisor — parallel context+intent xong trong {elapsed_ms}ms | "
        f"agent={result.agent} | nguồn={result.source}",
        indent=3,
    )
    from app.observability.flow_log import flow_timing

    flow_timing("Supervisor context+intent", elapsed_ms, indent=3)

    return {**ctx_updates, **_routing_from_intent(result, state)}


def route_to_agent(state: SyncAgentState) -> str:
    """Conditional edge: trả tên node specialist."""
    return state.get("target_agent") or "coach"
