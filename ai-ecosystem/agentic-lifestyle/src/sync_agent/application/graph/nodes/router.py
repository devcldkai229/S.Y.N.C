from sync_agent.application.graph.deps import AgentGraphDependencies
from sync_agent.application.prompts.worker_prompts import router_system_prompt
from sync_agent.domain.graph.state import AgentState
from sync_agent.domain.schemas.agent.intent import AgentIntent


async def router_node(state: AgentState, deps: AgentGraphDependencies) -> dict:
    message = (state.get("latest_message") or "").strip()
    intent = await deps.router.classify(message, system_prompt=router_system_prompt())
    return {"current_intent": intent}


def route_by_intent(state: AgentState) -> str:
    intent = state.get("current_intent")
    if intent == AgentIntent.NUTRITION or intent == AgentIntent.NUTRITION.value:
        return "nutrition_worker"
    if intent == AgentIntent.WORKOUT_RAG or intent == AgentIntent.WORKOUT_RAG.value:
        return "workout_rag_worker"
    if intent == AgentIntent.WORKOUT_ACTION or intent == AgentIntent.WORKOUT_ACTION.value:
        return "workout_action_worker"
    return "unknown_worker"
