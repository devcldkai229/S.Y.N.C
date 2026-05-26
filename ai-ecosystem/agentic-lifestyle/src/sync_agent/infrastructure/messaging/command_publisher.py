"""Port for publishing agent commands to the message broker."""

from __future__ import annotations

from typing import Protocol

from sync_agent.domain.schemas.messaging.agent_command import AgentCommandMessage


class CommandPublisherPort(Protocol):
    async def publish(self, message: AgentCommandMessage, *, routing_key: str) -> None: ...

    async def aclose(self) -> None: ...
