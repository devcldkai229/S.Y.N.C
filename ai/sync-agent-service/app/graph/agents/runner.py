"""Shared agent runner — bind_tools + ToolRunContext side-effects + stream pha cuối."""
from __future__ import annotations

from time import perf_counter
from typing import Any

from langchain_core.runnables import RunnableConfig

from app.graph.agents.base import accumulate_tokens, is_sensitive, system_prompt
from app.graph.toolrunner import resolve_tool_calls, stream_final_response
from app.models.router import get_bound_tool_model, get_chat_model
from app.observability.flow_log import flow, flow_timing
from app.state import SyncAgentState
from app.tools.catalog import build_impls, tool_schemas, tools_for_agent
from app.tools.context import ToolRunContext


def _greeting_heuristic(state: SyncAgentState) -> bool:
    return (
        state.get("intent_source") == "heuristic"
        and state.get("intent_reason") == "greeting"
    )


async def run_tool_agent(
    state: SyncAgentState,
    agent_name: str,
    *,
    extra_context: str = "",
    extra_tool_names: list[str] | None = None,
    extra_impls: dict[str, Any] | None = None,
    extra_schemas: list[dict[str, Any]] | None = None,
    fallback_text: str = "",
    config: RunnableConfig | None = None,
    use_bound_cache: bool = True,
) -> dict[str, Any]:
    user_id = state["user_id"]
    tier = state.get("model_tier", "mid")
    ctx = ToolRunContext(user_id=user_id, state=dict(state))

    skip_tools = tier == "small"
    names = [] if skip_tools else list(tools_for_agent(agent_name))
    if extra_tool_names and not skip_tools:
        names.extend(extra_tool_names)

    impls = build_impls(ctx, names)
    if extra_impls and not skip_tools:
        impls.update(extra_impls)

    schemas = tool_schemas(names)
    if extra_schemas and not skip_tools:
        schemas.extend(extra_schemas)

    system = system_prompt(state, agent_name, extra_context=extra_context or None)
    sensitive = is_sensitive(state)
    if skip_tools and _greeting_heuristic(state):
        sensitive = False

    if use_bound_cache and not extra_impls and not extra_schemas and not skip_tools:
        model = get_bound_tool_model(tier, agent_name, sensitive)
    else:
        base_model = get_chat_model(tier, sensitive=sensitive)
        model = (
            base_model.bind_tools(schemas)
            if schemas and hasattr(base_model, "bind_tools")
            else base_model
        )

    flow(f"Agent [{agent_name}] — tier={tier} | tools={names}", indent=3)

    text = fallback_text or f"[{agent_name}] Mình sẵn sàng hỗ trợ bạn."
    tokens = state.get("tokens_used", 0)

    try:
        from langchain_core.messages import SystemMessage

        messages = [SystemMessage(content=system), *state.get("messages", [])]

        # Tier small: giữ tối đa vài message gần nhất để tránh context contamination.
        # Model nhỏ dễ bị "nhiễu" bởi history dài (ví dụ: lẫn protein vào câu stress).
        _MAX_HISTORY_SMALL = 4  # system + 4 messages (2 lượt hỏi-đáp)
        if tier == "small" and len(messages) > 1 + _MAX_HISTORY_SMALL:
            messages = [messages[0], *messages[-_MAX_HISTORY_SMALL:]]
            flow(
                f"Agent [{agent_name}] — trim history → {len(messages)} msgs (tier=small)",
                indent=4,
            )

        stream_only = skip_tools or not impls
        t0 = perf_counter()
        if stream_only:
            text, last = await stream_final_response(model, messages, config=config)
        else:
            convo = await resolve_tool_calls(model, messages, impls, config=config)
            if ctx.next_agent:
                # Hop này đã bàn giao (tool handoff). Narration của nó chỉ là lời
                # "mình không thể... sẽ chuyển bạn" — mâu thuẫn với câu trả lời thật
                # của agent kế tiếp và bị nối liền trong bubble. UI đã có chip
                # "Chuyển sang X" từ SSE handoff nên bỏ hẳn narration của hop này.
                text, last = "", None
                flow(
                    f"Agent [{agent_name}] — handoff → {ctx.next_agent}, bỏ narration hop",
                    indent=4,
                )
            else:
                text, last = await stream_final_response(model, convo, config=config)
        flow_timing(
            f"Agent [{agent_name}] LLM",
            int((perf_counter() - t0) * 1000),
            indent=4,
        )
        if not text and last is not None:
            text = getattr(last, "content", "") or text
        tokens = accumulate_tokens(state, last, system) if last is not None else tokens
    except Exception as exc:  # pragma: no cover
        flow(
            f"Agent [{agent_name}] — LLM/tool lỗi, dùng fallback | {type(exc).__name__}: {exc}",
            indent=3,
        )

    # Hop đã bàn giao: không phát final_response (kể cả fallback) — câu trả lời
    # thật thuộc về agent kế tiếp.
    final = "" if ctx.next_agent else (text or fallback_text)
    out: dict[str, Any] = {"final_response": final, "tokens_used": tokens}
    out.update(ctx.merge_into_agent_output())
    return out
