from sync_agent.domain.graph.state import AgentState, ChatTurn, merge_tool_calls, supports_langchain_messages
from sync_agent.domain.schemas.agent.intent import AgentIntent
from sync_agent.domain.schemas.agent.jit_context import JitContext
from sync_agent.domain.schemas.agent.llm_output import ToolCall


def test_agent_state_typed_dict_keys() -> None:
    state: AgentState = {
        "user_id": "user-1",
        "session_id": "sess-1",
        "latest_message": "Đổi lịch tập chân sang thứ sáu",
        "current_intent": AgentIntent.WORKOUT_ACTION,
        "jit_context": JitContext(),
        "spoken_response": None,
        "tool_calls": [],
    }
    assert state["current_intent"] == AgentIntent.WORKOUT_ACTION


def test_merge_chat_history() -> None:
    from sync_agent.domain.graph.state import _merge_chat_history

    merged = _merge_chat_history(
        [ChatTurn(role="user", content="hi")],
        ChatTurn(role="assistant", content="hello"),
    )
    assert len(merged) == 2
    assert merged[1].content == "hello"


def test_merge_tool_calls() -> None:
    left = [ToolCall(action="A", payload={})]
    right = [{"action": "B", "payload": {"x": 1}}]
    merged = merge_tool_calls(left, right)
    assert [t.action for t in merged] == ["A", "B"]


def test_supports_langchain_messages_is_bool() -> None:
    assert isinstance(supports_langchain_messages(), bool)
