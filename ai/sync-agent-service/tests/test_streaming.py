"""Streaming — resolve tools + astream pha cuối."""
from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest

from app.graph.toolrunner import resolve_tool_calls, stream_final_response


class _Chunk:
    def __init__(self, content: str) -> None:
        self.content = content


@pytest.mark.asyncio
async def test_stream_final_emits_multiple_chunks():
    model = MagicMock()

    async def _astream(_convo, **kwargs):
        for piece in ("Hel", "lo"):
            yield _Chunk(piece)

    model.astream = _astream
    text, last = await stream_final_response(model, [])
    assert text == "Hello"
    assert last is not None


@pytest.mark.asyncio
async def test_resolve_no_tools_then_stream():
    model = MagicMock()
    model.ainvoke = AsyncMock(return_value=MagicMock(tool_calls=[], content="unused"))
    convo = await resolve_tool_calls(model, [], {})
    assert convo == []
    chunks = ["A", "B"]
    model.astream = lambda _c, **kw: _async_iter(chunks)
    text, _ = await stream_final_response(model, convo)
    assert text == "AB"


async def _async_iter(parts: list[str]):
    for p in parts:
        yield _Chunk(p)
