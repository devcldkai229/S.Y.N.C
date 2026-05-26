from sync_agent.application.graph.deps import AgentGraphDependencies
from sync_agent.application.prompts.worker_prompts import workout_action_system_prompt
from sync_agent.domain.graph.state import AgentState


async def workout_action_worker_node(state: AgentState, deps: AgentGraphDependencies) -> dict:
    message = state.get("latest_message") or ""
    output = await deps.worker.generate(
        system_prompt=workout_action_system_prompt(state.get("jit_context")),
        user_message=message,
    )
    return {
        "spoken_response": output.spoken_response,
        "tool_calls": output.tool_calls,
    }
