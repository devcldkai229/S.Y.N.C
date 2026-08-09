"""Tool-calling runner — resolve tool rounds (ainvoke+gather), stream pha cuối ở agent."""
from __future__ import annotations

import asyncio
from time import perf_counter
from typing import Any, Awaitable, Callable

from app.observability.flow_log import flow, flow_data, flow_timing

# SSE in main.py only forwards on_chat_model_stream events that carry this tag.
STREAM_FINAL_TAG = "stream_final_response"


def _config_with_stream_final_tag(config: Any = None) -> dict[str, Any]:
    """Merge parent RunnableConfig with stream_final_response tag for SSE filtering."""
    base: dict[str, Any] = {}
    if isinstance(config, dict):
        base = dict(config)
    elif config is not None:
        # RunnableConfig is a TypedDict / dict-like
        try:
            base = dict(config)
        except Exception:
            base = {"configurable": getattr(config, "get", lambda *_: None)("configurable")}
    tags = list(base.get("tags") or [])
    if STREAM_FINAL_TAG not in tags:
        tags.append(STREAM_FINAL_TAG)
    base["tags"] = tags
    return base


def _tool_message_content(result: Any) -> str:
    """Keep pending_confirmation ToolMessages prose-only so the agent does not echo JSON."""
    if isinstance(result, dict) and result.get("status") == "pending_confirmation":
        msg = str(result.get("message") or "").strip()
        action_id = result.get("action_id") or ""
        mode = result.get("mode") or ""
        parts = [msg] if msg else ["Đã chuẩn bị lịch — chờ bạn xác nhận."]
        meta: list[str] = []
        if mode:
            meta.append(f"mode={mode}")
        if action_id:
            meta.append(f"action_id={action_id}")
        meta.append("status=pending_confirmation")
        parts.append(f"({', '.join(meta)})")
        return " ".join(parts)
    return str(result)


async def _execute_tool(
    call: dict[str, Any],
    tool_impls: dict[str, Callable[..., Awaitable[Any]]],
) -> tuple[dict[str, Any], Any]:
    name = call.get("name")
    args = call.get("args", {}) or {}
    flow_data(f"Tool — gọi [{name}]", args, indent=4, max_len=200)
    impl = tool_impls.get(name)
    try:
        result = await impl(**args) if impl else {"error": f"unknown tool {name}"}
        flow_data(f"Tool — [{name}] kết quả", result, indent=4, max_len=200)
    except Exception as exc:
        from app.tools.dotnet import readable_error

        result = {"error": readable_error(exc)}
        flow(f"Tool — [{name}] LỖI: {result['error']}", indent=4)
    return call, result


async def resolve_tool_calls(
    model: Any,
    messages: list[Any],
    tool_impls: dict[str, Callable[..., Awaitable[Any]]],
    *,
    max_iters: int = 3,
    config: Any = None,
) -> list[Any]:
    """Pha giải tool: ainvoke + thực thi tool song song. Trả convo sẵn sàng để astream."""
    from langchain_core.messages import HumanMessage, ToolMessage

    convo = list(messages)
    invoke_kw = {"config": config} if config is not None else {}

    for iteration in range(max_iters):
        t0 = perf_counter()
        last = await model.ainvoke(convo, **invoke_kw)
        flow_timing("Coach ainvoke (tool phase)", int((perf_counter() - t0) * 1000), indent=4)
        tool_calls = getattr(last, "tool_calls", None) or []
        if not tool_calls:
            # Model produced a text response — no more tools needed
            return convo
        convo.append(last)
        pairs = await asyncio.gather(
            *(_execute_tool(call, tool_impls) for call in tool_calls),
            return_exceptions=True,
        )
        for item in pairs:
            if isinstance(item, BaseException):
                flow(f"Tool — gather LỖI: {item}", indent=4)
                continue
            call, result = item
            convo.append(
                ToolMessage(
                    content=_tool_message_content(result),
                    tool_call_id=call.get("id", call.get("name", "")),
                )
            )

        # On the last iteration, add a stop hint so the model knows to produce text
        if iteration == max_iters - 1:
            convo.append(HumanMessage(
                content="Dựa trên kết quả tool ở trên, hãy trả lời câu hỏi của tôi bằng văn bản. Đừng gọi thêm tool nữa."
            ))

    return convo


async def stream_final_response(
    model: Any,
    convo: list[Any],
    *,
    config: Any = None,
) -> tuple[str, Any]:
    """Pha trả lời cuối — astream để LangGraph phát on_chat_model_stream.

    Tags the run with stream_final_response so SSE only forwards these tokens.
    If the model tries to call tools again (streaming tool_call chunks with no text content),
    fall back to a non-streaming ainvoke with tool_choice disabled.
    """
    stream_kw = {"config": _config_with_stream_final_tag(config)}
    parts: list[str] = []
    last_chunk: Any = None
    t0 = perf_counter()
    first_token_logged = False
    has_tool_calls = False

    async for chunk in model.astream(convo, **stream_kw):
        last_chunk = chunk
        piece = getattr(chunk, "content", "") or ""
        # Detect tool_call chunks (AIMessageChunk with tool_call_chunks)
        if not piece and hasattr(chunk, "tool_call_chunks") and getattr(chunk, "tool_call_chunks", None):
            has_tool_calls = True
        if piece:
            if not first_token_logged:
                flow_timing("Coach astream TTFT", int((perf_counter() - t0) * 1000), indent=4)
                first_token_logged = True
            parts.append(piece)

    text = "".join(parts)

    # If the stream produced tool_calls but no text, try forcing a text-only response
    if has_tool_calls and not text:
        flow("stream_final_response — model produced tool_calls instead of text; forcing text-only fallback", indent=4)
        try:
            forced = await model.ainvoke(convo)
            text = getattr(forced, "content", "") or ""
            last_chunk = forced
        except Exception as exc:
            flow(f"stream_final_response forced-text fallback LỖI: {exc}", indent=4)

    return text, last_chunk


async def run_with_tools(
    model: Any,
    messages: list[Any],
    tool_impls: dict[str, Callable[..., Awaitable[Any]]],
    *,
    max_iters: int = 3,
    config: Any = None,
) -> Any:
    """Backward-compat: resolve + stream, trả chunk cuối (AIMessage-like)."""
    from langchain_core.messages import AIMessage

    convo = await resolve_tool_calls(model, messages, tool_impls, max_iters=max_iters, config=config)
    text, last = await stream_final_response(model, convo, config=config)
    if last is not None and hasattr(last, "content"):
        return last
    return AIMessage(content=text or "")
