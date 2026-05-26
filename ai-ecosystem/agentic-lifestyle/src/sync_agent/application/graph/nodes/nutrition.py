from sync_agent.application.graph.deps import AgentGraphDependencies
from sync_agent.application.guardrails.nutrition_guardrail import validate_nutrition_response
from sync_agent.application.prompts.worker_prompts import nutrition_system_prompt
from sync_agent.domain.graph.state import AgentState


async def nutrition_worker_node(state: AgentState, deps: AgentGraphDependencies) -> dict:
    message = state.get("latest_message") or ""
    guardrail_note = state.get("guardrail_violation")
    output = await deps.worker.generate(
        system_prompt=nutrition_system_prompt(
            state.get("jit_context"),
            guardrail_note=guardrail_note,
        ),
        user_message=message,
    )
    return {
        "spoken_response": output.spoken_response,
        "tool_calls": output.tool_calls,
    }


async def nutrition_guardrail_node(state: AgentState, deps: AgentGraphDependencies) -> dict:
    spoken = state.get("spoken_response") or ""
    jit = state.get("jit_context")
    violations = validate_nutrition_response(spoken, jit)

    if not violations:
        return {"guardrail_violation": None}

    retries = (state.get("guardrail_retry_count") or 0) + 1
    violation_text = "; ".join(violations)

    if retries >= deps.settings.nutrition_guardrail_max_retries:
        return {
            "guardrail_retry_count": retries,
            "guardrail_violation": None,
            "spoken_response": (
                "Mình xin lỗi — không thể đưa ra gợi ý món ăn an toàn với dị ứng của bạn lúc này. "
                "Bạn mô tả lại bữa ăn hoặc kiểm tra nhãn thực phẩm nhé."
            ),
            "tool_calls": [],
        }

    return {
        "guardrail_retry_count": retries,
        "guardrail_violation": violation_text,
    }


def route_after_nutrition_guardrail(state: AgentState, deps: AgentGraphDependencies) -> str:
    if state.get("guardrail_violation"):
        if (state.get("guardrail_retry_count") or 0) < deps.settings.nutrition_guardrail_max_retries:
            return "nutrition_worker"
    return "tool_execution"
