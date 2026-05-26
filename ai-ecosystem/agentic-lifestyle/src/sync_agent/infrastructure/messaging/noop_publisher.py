"""No-op publisher for unit tests and agent-disabled mode."""

from __future__ import annotations

import structlog

from sync_agent.domain.schemas.messaging.agent_command import AgentCommandMessage

logger = structlog.get_logger(__name__)


class NoOpCommandPublisher:
    async def publish(self, message: AgentCommandMessage, *, routing_key: str) -> None:
        logger.debug(
            "messaging.noop.publish",
            action=message.action,
            routing_key=routing_key,
            idempotency_key=message.idempotency_key[:12],
        )

    async def aclose(self) -> None:
        return None
