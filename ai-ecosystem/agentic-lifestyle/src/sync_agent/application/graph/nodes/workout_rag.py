from sync_agent.application.graph.deps import AgentGraphDependencies
from sync_agent.application.prompts.worker_prompts import workout_rag_system_prompt
from sync_agent.domain.graph.state import AgentState


async def workout_rag_worker_node(state: AgentState, deps: AgentGraphDependencies) -> dict:
    message = state.get("latest_message") or ""
    rag_text = "Không có dữ liệu catalog."

    if deps.rag_search is not None:
        try:
            result = await deps.rag_search.search(message)
            rag_text = result.to_prompt_context()
        except Exception:
            rag_text = "Lỗi truy vấn catalog — trả lời chung, không bịa chi tiết kỹ thuật."

    output = await deps.worker.generate(
        system_prompt=workout_rag_system_prompt(state.get("jit_context"), rag_text),
        user_message=message,
    )
    return {
        "spoken_response": output.spoken_response,
        "tool_calls": output.tool_calls,
        "rag_context": rag_text,
    }
