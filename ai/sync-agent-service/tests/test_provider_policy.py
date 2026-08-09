"""Provider policy — OpenAI-only, biometric fail-safe."""
from __future__ import annotations

import pytest

from app.config import MODEL_REGISTRY, ModelSpec, ModelTier
from app.graph.agents.base import is_sensitive
from app.models.router import _assert_safe, resolve_spec, resolve_tier
from app.state import initial_state


@pytest.mark.parametrize("tier", list(ModelTier))
def test_sensitive_always_openai(tier: ModelTier):
    if tier in (ModelTier.EMBED, ModelTier.REALTIME):
        pytest.skip("embed/realtime không qua get_chat_model sensitive path")
    spec = resolve_spec(tier, sensitive=True)
    assert spec.provider == "openai"


def test_failsafe_raises():
    # Provider non-OpenAI (vd ollama local) không được nhận biometric.
    non_openai = ModelSpec("ollama", "llama3", pii_safe=False)
    with pytest.raises(ValueError, match="BIOMETRIC"):
        _assert_safe(non_openai, sensitive=True)


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


def test_resolve_tier_keeps_openai_tiers_when_sensitive():
    # Mọi tier đều OpenAI → sensitive không cần nâng tier nữa.
    assert resolve_tier(ModelTier.SMALL, sensitive=True) == ModelTier.SMALL
    assert resolve_tier(ModelTier.MID, sensitive=True) == ModelTier.MID
