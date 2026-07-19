"""Mutable context passed into tool implementations (handoff, display_payload, pending)."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class ToolRunContext:
    user_id: str
    state: dict[str, Any]
    tools_called: list[str] = field(default_factory=list)
    tool_calls_log: list[dict[str, Any]] = field(default_factory=list)
    display_payload: list[dict[str, Any]] = field(default_factory=list)
    pending_actions: list[dict[str, Any]] = field(default_factory=list)
    next_agent: str | None = None
    handoff_reason: str | None = None

    def merge_into_agent_output(self) -> dict[str, Any]:
        """Convert side-effects into LangGraph state patch."""
        out: dict[str, Any] = {}
        if self.next_agent:
            out["next_agent"] = self.next_agent
        if self.handoff_reason:
            out["handoff_reason"] = self.handoff_reason
        if self.display_payload:
            out["display_payload"] = [
                *(self.state.get("display_payload") or []),
                *self.display_payload,
            ]
        if self.pending_actions:
            out["pending_actions"] = [
                *(self.state.get("pending_actions") or []),
                *self.pending_actions,
            ]
            out["requires_confirmation"] = True
        if self.tools_called or self.tool_calls_log:
            prev_results = self.state.get("tool_results") or {}
            prev_called = list(prev_results.get("_tools_called") or [])
            prev_outputs = list(prev_results.get("_outputs") or [])
            out["tool_results"] = {
                **prev_results,
                "_tools_called": prev_called + self.tools_called,
                "_outputs": prev_outputs + self.tool_calls_log,
            }
        return out


async def safe_tool_call(fn, **kwargs) -> dict[str, Any]:
    """Never raise — tool errors become `{error: ...}` for the LLM."""
    try:
        result = await fn(**kwargs)
        if isinstance(result, dict):
            return result
        return {"value": result}
    except Exception as exc:
        from app.tools.dotnet import readable_error

        return {"error": readable_error(exc)}
