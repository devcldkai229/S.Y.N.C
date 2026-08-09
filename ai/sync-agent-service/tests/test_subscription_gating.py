"""Supervisor subscription model cap."""
from __future__ import annotations

from app.config import ModelTier
from app.graph.supervisor import _routing_from_intent
from app.state import SyncAgentState


class _FakeIntent:
    agent = "coach"
    confidence = 0.9
    source = "test"
    reason = "complex"
    language = "vi"

    def tier_for_reply(self) -> ModelTier:
        return ModelTier.LARGE


def test_free_complex_intent_caps_to_mid():
    state: SyncAgentState = {
        "user_id": "u1",
        "session_id": "s1",
        "subscription_tier": "Free",
        "token_budget": 8000,
        "tokens_used": 0,
        "guardrail_flags": [],
    }
    out = _routing_from_intent(_FakeIntent(), state)
    assert out["model_tier"] == ModelTier.MID.value
    assert out["subscription_tier"] == "Free"


def test_premium_allows_large():
    state: SyncAgentState = {
        "user_id": "u1",
        "session_id": "s1",
        "subscription_tier": "Premium",
        "token_budget": 12000,
        "tokens_used": 0,
        "guardrail_flags": [],
    }
    out = _routing_from_intent(_FakeIntent(), state)
    assert out["model_tier"] == ModelTier.LARGE.value
