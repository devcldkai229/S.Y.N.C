"""Unit tests — handoff routing."""
from __future__ import annotations

from app.graph.routing import route_after_agent


def test_handoff_when_next_agent_set():
    state = {"next_agent": "commerce", "handoff_count": 0}
    assert route_after_agent(state) == "prepare_handoff"


def test_no_handoff_when_cap_reached():
    state = {"next_agent": "commerce", "handoff_count": 1}
    assert route_after_agent(state) == "guardrail_out"
