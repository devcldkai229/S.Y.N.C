"""
Compile LangGraph for SYNC agent brain.

Flow:
  router → (nutrition | workout_rag | workout_action | unknown)
  nutrition → guardrail → (retry nutrition | tool_execution)
  workout_* / unknown → tool_execution → END
"""

from __future__ import annotations

from functools import partial

from langgraph.graph import END, StateGraph

from sync_agent.application.graph.deps import AgentGraphDependencies
from sync_agent.application.graph.nodes.nutrition import (
    nutrition_guardrail_node,
    nutrition_worker_node,
    route_after_nutrition_guardrail,
)
from sync_agent.application.graph.nodes.router import router_node, route_by_intent
from sync_agent.application.graph.nodes.tool_execution import tool_execution_node
from sync_agent.application.graph.nodes.unknown import unknown_worker_node
from sync_agent.application.graph.nodes.workout_action import workout_action_worker_node
from sync_agent.application.graph.nodes.workout_rag import workout_rag_worker_node
from sync_agent.domain.graph.state import AgentState

_TOOL_EXECUTION_NODE = "tool_execution"


def compile_agent_graph(
    deps: AgentGraphDependencies,
    *,
    interrupt_before_tool_execution: bool = False,
):
    """
    Compile the agent graph.

    When interrupt_before_tool_execution=True (voice pipeline), the graph pauses
    after workers/guardrail so TTS can stream spoken_response while tool_execution runs.
    """
    graph = StateGraph(AgentState)

    graph.add_node("router", partial(router_node, deps=deps))
    graph.add_node("nutrition_worker", partial(nutrition_worker_node, deps=deps))
    graph.add_node("nutrition_guardrail", partial(nutrition_guardrail_node, deps=deps))
    graph.add_node("workout_rag_worker", partial(workout_rag_worker_node, deps=deps))
    graph.add_node("workout_action_worker", partial(workout_action_worker_node, deps=deps))
    graph.add_node("unknown_worker", partial(unknown_worker_node, deps=deps))
    graph.add_node(_TOOL_EXECUTION_NODE, partial(tool_execution_node, deps=deps))

    graph.set_entry_point("router")

    graph.add_conditional_edges(
        "router",
        route_by_intent,
        {
            "nutrition_worker": "nutrition_worker",
            "workout_rag_worker": "workout_rag_worker",
            "workout_action_worker": "workout_action_worker",
            "unknown_worker": "unknown_worker",
        },
    )

    graph.add_edge("nutrition_worker", "nutrition_guardrail")
    graph.add_conditional_edges(
        "nutrition_guardrail",
        partial(route_after_nutrition_guardrail, deps=deps),
        {
            "nutrition_worker": "nutrition_worker",
            "tool_execution": _TOOL_EXECUTION_NODE,
        },
    )

    graph.add_edge("workout_rag_worker", _TOOL_EXECUTION_NODE)
    graph.add_edge("workout_action_worker", _TOOL_EXECUTION_NODE)
    graph.add_edge("unknown_worker", _TOOL_EXECUTION_NODE)
    graph.add_edge(_TOOL_EXECUTION_NODE, END)

    interrupt: list[str] | None = (
        [_TOOL_EXECUTION_NODE] if interrupt_before_tool_execution else None
    )
    return graph.compile(interrupt_before=interrupt)
