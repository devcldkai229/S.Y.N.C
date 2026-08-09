"""Free commerce gate + Premium model tier helpers."""
from __future__ import annotations

from app.config import ModelTier
from app.graph.subscription_gating import (
    commerce_allowed,
    ensure_commerce_model_tier,
    normalize_tier,
)


def test_commerce_allowed_tiers():
    assert commerce_allowed("Free") is False
    assert commerce_allowed("free") is False
    assert commerce_allowed("Premium") is True
    assert commerce_allowed("Ultra") is True
    assert commerce_allowed(None) is False


def test_ensure_commerce_model_tier_forces_mid():
    assert ensure_commerce_model_tier("Premium", ModelTier.SMALL) == ModelTier.MID.value
    assert ensure_commerce_model_tier("Ultra", "small") == ModelTier.MID.value
    assert ensure_commerce_model_tier("Free", ModelTier.SMALL) == ModelTier.SMALL.value
    assert ensure_commerce_model_tier("Premium", ModelTier.MID) == ModelTier.MID.value


def test_normalize_tier():
    assert normalize_tier("premium") == "Premium"
    assert normalize_tier("") == "Free"
