"""Publish LLM tool_calls to RabbitMQ with idempotent deduplication."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

import structlog

from sync_agent.application.graph.deps import AgentGraphDependencies
from sync_agent.application.tools.idempotency import build_idempotency_key
from sync_agent.application.tools.routing import resolve_routing_key
from sync_agent.domain.graph.state import AgentState
from sync_agent.domain.schemas.agent.llm_output import ToolCall
from sync_agent.domain.schemas.messaging.agent_command import AgentCommandMessage

logger = structlog.get_logger(__name__)


def _normalize_tool_calls(
    raw: list[ToolCall] | list[dict[str, Any]] | None,
) -> list[ToolCall]:
    if not raw:
        return []
    result: list[ToolCall] = []
    for item in raw:
        if isinstance(item, ToolCall):
            result.append(item)
        else:
            result.append(ToolCall.model_validate(item))
    return result


async def tool_execution_node(state: AgentState, deps: AgentGraphDependencies) -> dict:
    user_id = (state.get("user_id") or "").strip()
    session_id = state.get("session_id")
    turn_timestamp = state.get("turn_timestamp") or datetime.now(timezone.utc).isoformat()
    tool_calls = _normalize_tool_calls(state.get("tool_calls"))

    if not tool_calls:
        return {"tool_execution_results": [], "executed_tool_ids": []}

    if not user_id:
        logger.warning("tool_execution.missing_user_id", tool_count=len(tool_calls))
        return {
            "tool_execution_results": [
                {"status": "skipped", "reason": "missing_user_id", "action": tc.action}
                for tc in tool_calls
            ],
        }

    results: list[dict[str, Any]] = []
    executed_keys: list[str] = list(state.get("executed_tool_ids") or [])

    for call in tool_calls:
        idempotency_key = build_idempotency_key(user_id, call.action, turn_timestamp)

        if idempotency_key in executed_keys:
            results.append(
                {
                    "action": call.action,
                    "status": "duplicate_skipped",
                    "idempotencyKey": idempotency_key,
                }
            )
            continue

        if await deps.idempotency_store.exists(idempotency_key):
            logger.info(
                "tool_execution.idempotent_skip",
                action=call.action,
                idempotency_key=idempotency_key[:12],
            )
            results.append(
                {
                    "action": call.action,
                    "status": "duplicate_skipped",
                    "idempotencyKey": idempotency_key,
                }
            )
            executed_keys.append(idempotency_key)
            continue

        message = AgentCommandMessage(
            idempotency_key=idempotency_key,
            user_id=user_id,
            session_id=session_id,
            action=call.action,
            payload=call.payload,
            published_at=datetime.now(timezone.utc),
            correlation_id=session_id,
        )
        routing_key = resolve_routing_key(call.action)

        try:
            await deps.command_publisher.publish(message, routing_key=routing_key)
            await deps.idempotency_store.mark(
                idempotency_key,
                ttl_sec=deps.settings.idempotency_ttl_sec,
            )
            executed_keys.append(idempotency_key)
            results.append(
                {
                    "action": call.action,
                    "status": "published",
                    "idempotencyKey": idempotency_key,
                    "routingKey": routing_key,
                }
            )
        except Exception as exc:
            logger.exception("tool_execution.publish_failed", action=call.action)
            results.append(
                {
                    "action": call.action,
                    "status": "failed",
                    "idempotencyKey": idempotency_key,
                    "error": str(exc),
                }
            )

    return {
        "tool_execution_results": results,
        "executed_tool_ids": executed_keys,
    }
