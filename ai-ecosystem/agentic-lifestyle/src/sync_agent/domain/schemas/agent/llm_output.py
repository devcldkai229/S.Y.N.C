"""Dual-output JSON contract from .cursorrules §2."""

from typing import Any

from pydantic import Field, field_validator

from sync_agent.domain.schemas.common import StrictModel


class ToolCall(StrictModel):
    """
    Single executable command for C# / RabbitMQ layer.
    Example: {"action": "RescheduleWorkout", "payload": {"date": "..."}}
    """

    action: str = Field(min_length=1)
    payload: dict[str, Any] = Field(default_factory=dict)


class LLMAgentOutput(StrictModel):
    """Required LLM response shape for every worker node."""

    spoken_response: str = Field(min_length=1)
    tool_calls: list[ToolCall] = Field(default_factory=list)

    @field_validator("spoken_response")
    @classmethod
    def _strip_spoken(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("spoken_response must not be empty")
        return stripped
