"""Smoke tests — cấu trúc & routing cơ bản không cần LLM/infra thật."""
from __future__ import annotations

import pytest

from app.config import MODEL_REGISTRY, ModelTier, get_settings
from app.graph.intent import _degraded
from app.graph.supervisor import supervisor
from app.models.router import escalate
from app.state import initial_state


def test_registry_covers_all_tiers():
    for tier in [ModelTier.NANO, ModelTier.SMALL, ModelTier.MID, ModelTier.LARGE]:
        assert tier in MODEL_REGISTRY


def test_settings_loads():
    s = get_settings()
    assert s.default_token_budget > 0
    assert s.intent_classifier_model  # cấu hình classifier tồn tại


def test_degraded_defaults_coach():
    assert _degraded("hôm nay ăn bao nhiêu calo").agent == "coach"


@pytest.mark.asyncio
async def test_supervisor_async_routes():
    from langchain_core.messages import HumanMessage

    st = initial_state(user_id="u1", session_id="s1")
    st["messages"] = [HumanMessage(content="hôm nay ăn bao nhiêu calo")]
    out = await supervisor(st)
    assert out["target_agent"] in {"coach", "nutrition", "workout", "commerce", "insight"}


def test_escalation_capped():
    assert escalate(ModelTier.MID).value == "large"
    assert escalate(ModelTier.LARGE).value == "large"  # không vượt trần
