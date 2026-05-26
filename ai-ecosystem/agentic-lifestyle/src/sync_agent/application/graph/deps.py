from dataclasses import dataclass

from sync_agent.application.jit_context_fetcher import JitContextFetcher
from sync_agent.core.config import Settings
from sync_agent.infrastructure.idempotency.memory_store import InMemoryIdempotencyStore
from sync_agent.infrastructure.llm.groq_router import GroqIntentRouter
from sync_agent.infrastructure.llm.openai_structured import OpenAIStructuredWorker
from sync_agent.infrastructure.messaging.command_publisher import CommandPublisherPort
from sync_agent.infrastructure.rag.exercise_catalog_search import ExerciseCatalogSearchService


@dataclass
class AgentGraphDependencies:
    settings: Settings
    router: GroqIntentRouter
    worker: OpenAIStructuredWorker
    jit_fetcher: JitContextFetcher
    command_publisher: CommandPublisherPort
    idempotency_store: InMemoryIdempotencyStore
    rag_search: ExerciseCatalogSearchService | None = None
