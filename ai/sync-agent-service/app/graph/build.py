"""Lắp ráp StateGraph cho MVP Chat:

  START -> guardrail_in -> supervisor (context + intent song song) -> {specialist}
       -> [handoff? -> supervisor] -> guardrail_out -> END
"""
from __future__ import annotations

from typing import Any

from app.graph.agents.coach import coach_agent
from app.graph.agents.commerce import commerce_agent
from app.graph.agents.insight import insight_agent
from app.graph.agents.nutrition import nutrition_agent
from app.graph.agents.workout import workout_agent
from app.graph.guardrails import guardrail_in, guardrail_out
from app.graph.routing import prepare_handoff, route_after_agent
from app.graph.supervisor import route_to_agent, supervisor
from app.state import SyncAgentState

_AGENT_NODES = {
    "coach": coach_agent,
    "workout": workout_agent,
    "nutrition": nutrition_agent,
    "commerce": commerce_agent,
    "insight": insight_agent,
}


def build_graph(checkpointer: Any | None = None):
    from langgraph.graph import END, START, StateGraph

    g = StateGraph(SyncAgentState)

    g.add_node("guardrail_in", guardrail_in)
    g.add_node("supervisor", supervisor)
    g.add_node("prepare_handoff", prepare_handoff)
    for name, fn in _AGENT_NODES.items():
        g.add_node(name, fn)
    g.add_node("guardrail_out", guardrail_out)

    g.add_edge(START, "guardrail_in")
    g.add_edge("guardrail_in", "supervisor")
    g.add_conditional_edges(
        "supervisor",
        route_to_agent,
        {name: name for name in _AGENT_NODES},
    )

    for name in _AGENT_NODES:
        g.add_conditional_edges(
            name,
            route_after_agent,
            {"prepare_handoff": "prepare_handoff", "guardrail_out": "guardrail_out"},
        )
    g.add_edge("prepare_handoff", "supervisor")
    g.add_edge("guardrail_out", END)

    return g.compile(checkpointer=checkpointer)
