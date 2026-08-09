"""Tiện ích dùng chung cho specialist agents.

Prompt đã chuyển sang `app/prompts/` (persona/safety/i18n). Module này chỉ giữ
helper thuần: lấy text, format user-context, cập nhật token đã dùng.
"""
from __future__ import annotations

from typing import Any

from app.models.usage import total_tokens
from app.prompts import build_agent_system_prompt
from app.state import SyncAgentState

# Field hồ sơ an toàn để tóm tắt vào prompt (đã de-identify ở context.py).
_CONTEXT_FIELDS = (
    "fitnessGoal", "experienceLevel", "activityLevel",
    "currentWeightKg", "targetWeightKg", "heightCm", "baseTDEE",
    "dailyProteinTargetGram", "dailyCarbTargetGram", "dailyFatTargetGram",
)


def last_user_text(state: SyncAgentState) -> str:
    msgs = state.get("messages", [])
    if not msgs:
        return ""
    c = getattr(msgs[-1], "content", "")
    return c if isinstance(c, str) else ""


def format_user_context(state: SyncAgentState) -> str | None:
    snap = state.get("user_snapshot") or {}
    pairs = [f"{k}={snap[k]}" for k in _CONTEXT_FIELDS if snap.get(k) is not None]

    # Injuries and dislikes: critical for safety and personalization
    injuries = snap.get("injuries") or []
    if injuries:
        pairs.append(f"injuries={', '.join(str(x) for x in injuries)}")

    dislikes = snap.get("dislikedFoods") or []
    if dislikes:
        pairs.append(f"dislikedFoods={', '.join(str(x) for x in dislikes)}")

    allergies = snap.get("allergies") or []
    if allergies:
        pairs.append(f"allergies={', '.join(str(x) for x in allergies)}")

    # Current datetime for temporal reasoning
    current_dt = state.get("current_datetime") or ""
    if current_dt:
        pairs.append(f"currentDateTime={current_dt}")

    return ", ".join(pairs) if pairs else None


def is_sensitive(state: SyncAgentState) -> bool:
    """True khi system prompt sẽ chèn biometric (user_snapshot de-identified)."""
    return format_user_context(state) is not None


def system_prompt(state: SyncAgentState, agent: str, extra_context: str | None = None) -> str:
    return build_agent_system_prompt(
        agent,
        persona=state.get("persona", "FriendlyBuddy"),
        motivation=state.get("motivation_style", "Supportive"),
        locale=state.get("locale", "vi"),
        user_context=format_user_context(state),
        extra_context=extra_context,
    )


def accumulate_tokens(state: SyncAgentState, response: Any, *prompt_texts: str) -> int:
    return state.get("tokens_used", 0) + total_tokens(response, *prompt_texts)
