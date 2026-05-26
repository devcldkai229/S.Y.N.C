from sync_agent.application.graph.nodes.nutrition import route_after_nutrition_guardrail
from sync_agent.application.graph.nodes.router import route_by_intent
from sync_agent.core.config import Settings
from sync_agent.domain.schemas.agent.intent import AgentIntent


def test_route_by_intent_nutrition() -> None:
    assert route_by_intent({"current_intent": AgentIntent.NUTRITION}) == "nutrition_worker"


def test_route_by_intent_workout_rag() -> None:
    assert route_by_intent({"current_intent": "workout_rag"}) == "workout_rag_worker"


def test_route_after_guardrail_retries() -> None:
    deps_settings = Settings(groq_api_key="x", openai_api_key="x", nutrition_guardrail_max_retries=3)
    from sync_agent.application.graph.deps import AgentGraphDependencies
    from sync_agent.infrastructure.idempotency.memory_store import InMemoryIdempotencyStore
    from sync_agent.infrastructure.messaging.noop_publisher import NoOpCommandPublisher
    from unittest.mock import MagicMock

    deps = AgentGraphDependencies(
        settings=deps_settings,
        router=MagicMock(),
        worker=MagicMock(),
        jit_fetcher=MagicMock(),
        command_publisher=NoOpCommandPublisher(),
        idempotency_store=InMemoryIdempotencyStore(),
    )
    assert (
        route_after_nutrition_guardrail(
            {"guardrail_violation": "allergen", "guardrail_retry_count": 1},
            deps,
        )
        == "nutrition_worker"
    )
    assert route_after_nutrition_guardrail({"guardrail_violation": None}, deps) == "tool_execution"
