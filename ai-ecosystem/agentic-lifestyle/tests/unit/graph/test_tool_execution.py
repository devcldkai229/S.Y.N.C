import pytest

from sync_agent.application.graph.deps import AgentGraphDependencies
from sync_agent.application.graph.nodes.tool_execution import tool_execution_node
from sync_agent.core.config import Settings
from sync_agent.domain.schemas.agent.llm_output import ToolCall
from sync_agent.infrastructure.idempotency.memory_store import InMemoryIdempotencyStore
from sync_agent.infrastructure.messaging.noop_publisher import NoOpCommandPublisher
from unittest.mock import AsyncMock, MagicMock


@pytest.fixture
def deps() -> AgentGraphDependencies:
    settings = Settings(
        groq_api_key="test",
        openai_api_key="test",
        rabbitmq_enabled=False,
    )
    return AgentGraphDependencies(
        settings=settings,
        router=MagicMock(),
        worker=MagicMock(),
        jit_fetcher=MagicMock(),
        command_publisher=NoOpCommandPublisher(),
        idempotency_store=InMemoryIdempotencyStore(),
    )


@pytest.mark.asyncio
async def test_publishes_each_tool_once(deps: AgentGraphDependencies) -> None:
    deps.command_publisher.publish = AsyncMock()  # type: ignore[method-assign]

    state = {
        "user_id": "11111111-1111-1111-1111-111111111111",
        "session_id": "sess-1",
        "turn_timestamp": "2026-05-22T12:00:00+00:00",
        "tool_calls": [
            ToolCall(action="RescheduleWorkout", payload={"date": "2026-05-25"}),
        ],
    }
    result = await tool_execution_node(state, deps)
    assert result["tool_execution_results"][0]["status"] == "published"
    deps.command_publisher.publish.assert_awaited_once()  # type: ignore[attr-defined]

    # Second run with same turn timestamp → duplicate skip
    result2 = await tool_execution_node({**state, **result}, deps)
    assert result2["tool_execution_results"][0]["status"] == "duplicate_skipped"
    deps.command_publisher.publish.assert_awaited_once()  # type: ignore[attr-defined]


@pytest.mark.asyncio
async def test_skips_without_user_id(deps: AgentGraphDependencies) -> None:
    result = await tool_execution_node(
        {
            "tool_calls": [ToolCall(action="RescheduleWorkout", payload={})],
            "turn_timestamp": "2026-05-22T12:00:00+00:00",
        },
        deps,
    )
    assert result["tool_execution_results"][0]["status"] == "skipped"
