from sync_agent.domain.graph.state import AgentState


async def unknown_worker_node(state: AgentState, _deps) -> dict:
    return {
        "spoken_response": (
            "Mình chưa chắc bạn cần hỗ trợ dinh dưỡng hay lịch tập. "
            "Bạn nói rõ hơn được không?"
        ),
        "tool_calls": [],
    }
