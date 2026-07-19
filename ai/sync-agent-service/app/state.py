"""LangGraph shared state cho toàn bộ multi-agent graph."""
from __future__ import annotations

from typing import Annotated, Any, Literal, TypedDict

try:  # cho phép import khi chưa cài langgraph (verify cú pháp)
    from langchain_core.messages import AnyMessage
    from langgraph.graph.message import add_messages
except Exception:  # pragma: no cover
    AnyMessage = Any  # type: ignore

    def add_messages(left, right):  # type: ignore
        return (left or []) + (right or [])


Channel = Literal["chat", "voice_async", "voice_realtime"]
Locale = Literal["vi", "en"]
Tier = Literal["nano", "small", "mid", "large", "realtime"]


class SyncAgentState(TypedDict, total=False):
    # --- Identity & context ---
    user_id: str
    session_id: str
    locale: Locale
    channel: Channel
    persona: str            # AgentPersona: StrictCoach/FriendlyBuddy/CalmMentor/EnergeticTrainer
    motivation_style: str   # MotivationStyle

    # --- Conversation ---
    messages: Annotated[list[AnyMessage], add_messages]
    user_snapshot: dict[str, Any]   # biometrics + AIContextProfile (cached, de-identified)

    subscription_tier: str  # Free | Premium | Ultra (từ JWT, không đưa vào prompt)

    # --- Routing & budget ---
    intent: str | None
    target_agent: str | None
    model_tier: Tier | None
    intent_confidence: float
    intent_source: str          # llm | cache | llm_degraded | heuristic | handoff
    intent_reason: str          # greeting | keyword | ...
    token_budget: int
    tokens_used: int

    # --- Handoff ---
    next_agent: str | None
    handoff_reason: str | None
    handoff_target: str | None      # bypass intent classify for 1 hop
    handoff_count: int

    # --- Temporal context ---
    current_datetime: str   # ISO-8601 local time injected each turn (e.g. "2026-07-01T16:30:00+07:00")
    user_timezone: str      # IANA timezone, e.g. "Asia/Ho_Chi_Minh"

    # --- Optional client location (for nearby partner search) ---
    user_latitude: float | None
    user_longitude: float | None

    # --- Session commerce cart (persisted via checkpointer) ---
    cart: list[dict[str, Any]]

    # --- Side-effects & control ---
    pending_actions: list[dict[str, Any]]   # vd. đặt hàng chờ confirm
    requires_confirmation: bool
    guardrail_flags: list[str]
    tool_results: dict[str, Any]
    display_payload: list[dict[str, Any]]
    final_response: str | None


def initial_state(
    *,
    user_id: str,
    session_id: str,
    channel: Channel = "chat",
    locale: Locale = "vi",
    token_budget: int = 8000,
) -> SyncAgentState:
    return SyncAgentState(
        user_id=user_id,
        session_id=session_id,
        channel=channel,
        locale=locale,
        persona="FriendlyBuddy",
        motivation_style="Supportive",
        messages=[],
        user_snapshot={},
        subscription_tier="Free",
        intent=None,
        target_agent=None,
        model_tier=None,
        handoff_count=0,
        next_agent=None,
        handoff_reason=None,
        handoff_target=None,
        current_datetime="",
        user_timezone="Asia/Ho_Chi_Minh",
        token_budget=token_budget,
        tokens_used=0,
        cart=[],
        pending_actions=[],
        requires_confirmation=False,
        guardrail_flags=[],
        tool_results={},
        display_payload=[],
        final_response=None,
    )
