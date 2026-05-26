"""
LangGraph state for SYNC agent turns.

Uses TypedDict (LangGraph convention) with optional reducers when langgraph is installed.
Falls back to plain list merge for chat/tool_calls without requiring langgraph at import time.
"""

from __future__ import annotations

from typing import Annotated, Any, NotRequired, TypedDict

from sync_agent.domain.schemas.agent.intent import AgentIntent
from sync_agent.domain.schemas.agent.jit_context import JitContext
from sync_agent.domain.schemas.agent.llm_output import ToolCall
from sync_agent.domain.schemas.common import StrictModel


class ChatTurn(StrictModel):
    """Lightweight message when LangChain BaseMessage is not required."""

    role: str  # "user" | "assistant" | "system"
    content: str


def _merge_chat_history(
    left: list[ChatTurn] | list[dict[str, Any]],
    right: list[ChatTurn] | list[dict[str, Any]] | ChatTurn | dict[str, Any],
) -> list[ChatTurn]:
    def _normalize(item: ChatTurn | dict[str, Any]) -> ChatTurn:
        if isinstance(item, ChatTurn):
            return item
        return ChatTurn.model_validate(item)

    base = [_normalize(m) for m in left] if left else []
    if isinstance(right, list):
        return base + [_normalize(m) for m in right]
    return base + [_normalize(right)]


def merge_tool_calls(
    left: list[ToolCall] | list[dict[str, Any]],
    right: list[ToolCall] | list[dict[str, Any]],
) -> list[ToolCall]:
    """Append tool calls across multi-step worker chains."""

    def _normalize(item: ToolCall | dict[str, Any]) -> ToolCall:
        if isinstance(item, ToolCall):
            return item
        return ToolCall.model_validate(item)

    return [_normalize(t) for t in left] + [_normalize(t) for t in right]


# Prefer LangGraph's add_messages when available (Phase 3 graph compile).
try:
    from langchain_core.messages import AnyMessage
    from langgraph.graph.message import add_messages as _lg_add_messages

    ChatHistory = Annotated[list[AnyMessage], _lg_add_messages]
    _LANGGRAPH_MESSAGES = True
except ImportError:
    ChatHistory = Annotated[list[ChatTurn], _merge_chat_history]
    _LANGGRAPH_MESSAGES = False


class AgentState(TypedDict, total=False):
    """
    Unified state passed between LangGraph nodes for one voice conversation.

    Required flow per turn:
      latest_message (STT) → fetch jit_context → route current_intent
      → worker sets spoken_response + tool_calls
    """

    # Session identity (from WebSocket session.bind)
    user_id: NotRequired[str]
    session_id: NotRequired[str]

    # Conversation
    chat_history: ChatHistory
    latest_message: NotRequired[str]

    # Routing
    current_intent: NotRequired[AgentIntent | str | None]

    # JIT system context from C# HTTP clients (populated per turn, never hallucinated)
    jit_context: NotRequired[JitContext | None]

    # Dual LLM output (.cursorrules)
    spoken_response: NotRequired[str | None]
    tool_calls: NotRequired[Annotated[list[ToolCall], merge_tool_calls]]

    # Workout RAG retrieval (pgvector)
    rag_context: NotRequired[str | None]

    # Nutrition guardrail retry loop
    guardrail_retry_count: NotRequired[int]
    guardrail_violation: NotRequired[str | None]

    # Turn metadata (idempotency + tracing)
    turn_timestamp: NotRequired[str | None]
    bearer_token: NotRequired[str | None]

    # Tool execution (Phase 5)
    executed_tool_ids: NotRequired[list[str]]
    tool_execution_results: NotRequired[list[dict[str, Any]]]

    # Pipeline metadata
    transcript_language: NotRequired[str | None]
    error: NotRequired[str | None]


def supports_langchain_messages() -> bool:
    """True when langgraph/langchain-core are installed."""
    return _LANGGRAPH_MESSAGES
