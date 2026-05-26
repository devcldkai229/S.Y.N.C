"""RabbitMQ command envelope consumed by C# .NET workers."""

from datetime import datetime
from typing import Any

from pydantic import Field

from sync_agent.domain.schemas.common import StrictModel


class AgentCommandMessage(StrictModel):
    """
    Async command published to RabbitMQ for core backend execution.

    C# consumers validate idempotencyKey (e.g. Redis) before mutating databases.
    """

    idempotency_key: str = Field(min_length=16)
    user_id: str = Field(min_length=1)
    session_id: str | None = None
    action: str = Field(min_length=1)
    payload: dict[str, Any] = Field(default_factory=dict)
    published_at: datetime
    source: str = "sync-agent"
    correlation_id: str | None = None
