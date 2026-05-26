"""High-level orchestration: JIT fetch → LangGraph → dual output + tool publish."""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from typing import Any
from uuid import UUID

import structlog

from sync_agent.application.graph.builder import compile_agent_graph
from sync_agent.application.graph.deps import AgentGraphDependencies
from sync_agent.application.jit_context_fetcher import JitContextFetcher
from sync_agent.application.tools.idempotency import new_turn_timestamp
from sync_agent.core.config import Settings
from sync_agent.domain.graph.state import AgentState
from sync_agent.domain.schemas.agent.jit_context import JitContext
from sync_agent.infrastructure.http.sync_api_client import SyncApiClient
from sync_agent.infrastructure.idempotency.memory_store import InMemoryIdempotencyStore
from sync_agent.infrastructure.llm.groq_router import GroqIntentRouter
from sync_agent.infrastructure.llm.openai_structured import OpenAIStructuredWorker
from sync_agent.infrastructure.messaging.command_publisher import CommandPublisherPort
from sync_agent.infrastructure.messaging.noop_publisher import NoOpCommandPublisher
from sync_agent.infrastructure.messaging.rabbitmq_publisher import RabbitMQCommandPublisher
from sync_agent.infrastructure.rag.exercise_catalog_search import ExerciseCatalogSearchService

logger = structlog.get_logger(__name__)

OnSpokenReady = Callable[[str], Awaitable[None]]

_SPOKEN_EMIT_NODES = frozenset(
    {
        "nutrition_guardrail",
        "workout_rag_worker",
        "workout_action_worker",
        "unknown_worker",
    }
)


def _merge_state(base: AgentState, update: dict[str, Any]) -> AgentState:
    merged: dict[str, Any] = dict(base)
    for key, value in update.items():
        if key == "tool_calls" and key in merged and value:
            existing = list(merged.get("tool_calls") or [])
            merged["tool_calls"] = existing + list(value)
        elif key == "chat_history" and key in merged and value:
            existing = list(merged.get("chat_history") or [])
            merged["chat_history"] = existing + list(value)
        else:
            merged[key] = value
    return merged  # type: ignore[return-value]


def _spoken_from_update(node_name: str, update: dict[str, Any], accumulated: AgentState) -> str | None:
    if node_name not in _SPOKEN_EMIT_NODES:
        return None
    if node_name == "nutrition_guardrail":
        if update.get("guardrail_violation"):
            return None
        return update.get("spoken_response") or accumulated.get("spoken_response")
    return update.get("spoken_response")


class AgentRunner:
    def __init__(self, deps: AgentGraphDependencies) -> None:
        self._deps = deps
        self._graph = compile_agent_graph(deps)

    @classmethod
    def from_settings(
        cls,
        settings: Settings,
        *,
        bearer_token: str | None = None,
        enable_rag: bool = True,
        command_publisher: CommandPublisherPort | None = None,
        idempotency_store: InMemoryIdempotencyStore | None = None,
    ) -> AgentRunner:
        settings.validate_agent_runtime()
        api = SyncApiClient(settings=settings, bearer_token=bearer_token)
        rag = ExerciseCatalogSearchService(settings=settings) if enable_rag else None

        if command_publisher is None:
            if settings.rabbitmq_enabled and settings.rabbitmq_url.strip():
                command_publisher = RabbitMQCommandPublisher(settings=settings)
            else:
                command_publisher = NoOpCommandPublisher()

        deps = AgentGraphDependencies(
            settings=settings,
            router=GroqIntentRouter(settings=settings),
            worker=OpenAIStructuredWorker(settings=settings),
            jit_fetcher=JitContextFetcher(api),
            command_publisher=command_publisher,
            idempotency_store=idempotency_store or InMemoryIdempotencyStore(),
            rag_search=rag,
        )
        return cls(deps)

    async def _build_initial_state(
        self,
        *,
        user_message: str,
        user_id: str | None,
        session_id: str | None,
        bearer_token: str | None,
        jit_context: JitContext | None,
        fetch_jit: bool,
        turn_timestamp: str | None,
    ) -> AgentState:
        ctx = jit_context
        if fetch_jit and ctx is None:
            uid = UUID(user_id) if user_id else None
            ctx = await self._deps.jit_fetcher.fetch(user_id=uid)

        return {
            "latest_message": user_message,
            "user_id": user_id,
            "session_id": session_id,
            "bearer_token": bearer_token,
            "jit_context": ctx,
            "guardrail_retry_count": 0,
            "guardrail_violation": None,
            "turn_timestamp": turn_timestamp or new_turn_timestamp(),
            "executed_tool_ids": [],
            "tool_execution_results": [],
        }

    async def run_turn(
        self,
        *,
        user_message: str,
        user_id: str | None = None,
        session_id: str | None = None,
        bearer_token: str | None = None,
        jit_context: JitContext | None = None,
        fetch_jit: bool = True,
        turn_timestamp: str | None = None,
    ) -> AgentState:
        initial = await self._build_initial_state(
            user_message=user_message,
            user_id=user_id,
            session_id=session_id,
            bearer_token=bearer_token,
            jit_context=jit_context,
            fetch_jit=fetch_jit,
            turn_timestamp=turn_timestamp,
        )

        result = await self._graph.ainvoke(initial)
        logger.info(
            "agent.turn.complete",
            intent=str(result.get("current_intent")),
            tool_calls=len(result.get("tool_calls") or []),
            published=len(result.get("tool_execution_results") or []),
        )
        return result

    async def run_turn_streaming(
        self,
        *,
        user_message: str,
        user_id: str | None = None,
        session_id: str | None = None,
        bearer_token: str | None = None,
        on_spoken_ready: OnSpokenReady | None = None,
        jit_context: JitContext | None = None,
        fetch_jit: bool = True,
        turn_timestamp: str | None = None,
    ) -> AgentState:
        """
        Stream graph updates; invoke on_spoken_ready as soon as spoken_response is final
        (before tool_execution) so voice TTS can run concurrently with RabbitMQ publish.
        """
        initial = await self._build_initial_state(
            user_message=user_message,
            user_id=user_id,
            session_id=session_id,
            bearer_token=bearer_token,
            jit_context=jit_context,
            fetch_jit=fetch_jit,
            turn_timestamp=turn_timestamp,
        )

        accumulated: AgentState = dict(initial)
        spoken_emitted = False

        async for chunk in self._graph.astream(initial, stream_mode="updates"):
            for node_name, update in chunk.items():
                accumulated = _merge_state(accumulated, update)

                if on_spoken_ready and not spoken_emitted:
                    spoken = _spoken_from_update(node_name, update, accumulated)
                    if spoken:
                        await on_spoken_ready(spoken)
                        spoken_emitted = True

                if node_name == "tool_execution":
                    logger.info(
                        "agent.tools.executed",
                        results=len(update.get("tool_execution_results") or []),
                    )

        if on_spoken_ready and not spoken_emitted:
            fallback = accumulated.get("spoken_response")
            if fallback:
                await on_spoken_ready(fallback)

        logger.info(
            "agent.turn.streaming.complete",
            intent=str(accumulated.get("current_intent")),
            tool_calls=len(accumulated.get("tool_calls") or []),
        )
        return accumulated

    async def aclose(self) -> None:
        await self._deps.router.aclose()
        await self._deps.worker.aclose()
        await self._deps.command_publisher.aclose()
