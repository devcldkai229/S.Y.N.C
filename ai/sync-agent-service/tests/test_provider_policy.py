"""Provider policy — DeepSeek vs OpenAI, biometric fail-safe."""
from __future__ import annotations

import pytest

from app.config import MODEL_REGISTRY, ModelTier
from app.graph.agents.base import is_sensitive
from app.models.router import _assert_safe, resolve_spec, resolve_tier
from app.state import initial_state


@pytest.mark.parametrize("tier", list(ModelTier))
def test_sensitive_never_deepseek(tier: ModelTier):
    if tier in (ModelTier.EMBED, ModelTier.REALTIME):
        pytest.skip("embed/realtime không qua get_chat_model sensitive path")
    spec = resolve_spec(tier, sensitive=True)
    assert spec.provider == "openai"


def test_failsafe_raises():
    deepseek_spec = MODEL_REGISTRY[ModelTier.SMALL]
    assert deepseek_spec.provider == "deepseek"
    with pytest.raises(ValueError, match="BIOMETRIC"):
        _assert_safe(deepseek_spec, sensitive=True)


def test_is_sensitive_true_when_snapshot():
    st = initial_state(user_id="u1", session_id="s1")
    assert is_sensitive(st) is False

    st["user_snapshot"] = {}
    assert is_sensitive(st) is False

    st["user_snapshot"] = {"currentWeightKg": 70.5}
    assert is_sensitive(st) is True


def test_registry_api_only():
    for tier, spec in MODEL_REGISTRY.items():
        assert spec.provider != "ollama", f"{tier} still uses ollama in default registry"


def test_resolve_tier_escalates_non_openai_when_sensitive():
    assert resolve_tier(ModelTier.SMALL, sensitive=True) == ModelTier.MID
    assert resolve_tier(ModelTier.MID, sensitive=True) == ModelTier.MID
