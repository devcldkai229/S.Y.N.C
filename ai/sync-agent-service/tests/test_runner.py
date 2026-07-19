"""Agent runner — stream-only path when tools disabled."""
from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.graph.agents.runner import run_tool_agent


@pytest.mark.asyncio
async def test_skip_tools_streams_without_ainvoke():
    state = {
        "user_id": "u1",
        "model_tier": "small",
        "messages": [],
        "tokens_used": 0,
        "intent_source": "heuristic",
        "intent_reason": "greeting",
        "persona": "FriendlyBuddy",
        "locale": "vi",
    }
    mock_model = MagicMock()
    mock_model.astream = AsyncMock(return_value=_async_chunks(["Hi"]))
    mock_model.ainvoke = AsyncMock()

    with patch("app.graph.agents.runner.get_chat_model", return_value=mock_model):
        with patch("app.graph.agents.runner.stream_final_response", new_callable=AsyncMock) as mock_stream:
            mock_stream.return_value = ("Hi there", MagicMock(content="Hi there"))
            with patch("app.graph.agents.runner.resolve_tool_calls", new_callable=AsyncMock) as mock_resolve:
                out = await run_tool_agent(state, "coach", config={})

    mock_resolve.assert_not_called()
    mock_stream.assert_awaited_once()
    assert out["final_response"] == "Hi there"


async def _async_chunks(parts: list[str]):
    for p in parts:
        chunk = MagicMock()
        chunk.content = p
        yield chunk
