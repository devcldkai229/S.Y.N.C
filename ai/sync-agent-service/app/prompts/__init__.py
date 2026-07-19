"""Prompt library — tách prompt khỏi code, versioned, ưu tiên tiếng Việt.

Mọi prompt tập trung tại đây để dễ review/tune/A-B test, không rải rác trong agent.
Quy ước version: hằng *_VERSION để truy vết khi đổi prompt (gắn vào trace/audit).
"""
from app.prompts.agents import (
    AGENT_PROMPTS_VERSION,
    SAFETY_RULES_VI,
    build_agent_system_prompt,
)
from app.prompts.intent import (
    INTENT_PROMPT_VERSION,
    build_intent_messages,
)

__all__ = [
    "AGENT_PROMPTS_VERSION",
    "SAFETY_RULES_VI",
    "build_agent_system_prompt",
    "INTENT_PROMPT_VERSION",
    "build_intent_messages",
]
