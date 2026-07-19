"""Giới hạn model/token theo gói SubscriptionTier (Free / Premium / Ultra)."""
from __future__ import annotations

from app.config import ModelTier, get_settings


def normalize_tier(tier: str | None) -> str:
    if not tier:
        return "Free"
    normalized = tier.strip()
    if normalized.lower() == "free":
        return "Free"
    if normalized.lower() == "premium":
        return "Premium"
    if normalized.lower() == "ultra":
        return "Ultra"
    return normalized


def commerce_allowed(tier: str | None) -> bool:
    """Free không dùng commerce discovery/order; Premium/Ultra thì được."""
    return normalize_tier(tier) in ("Premium", "Ultra")


def insight_premium_allowed(tier: str | None) -> bool:
    """Thống kê đa kỳ + chart + dự đoán = Premium/Ultra."""
    return normalize_tier(tier) in ("Premium", "Ultra")


def require_premium(tier: str | None) -> bool:
    """Alias — True nếu được dùng insight nâng cao."""
    return insight_premium_allowed(tier)


def cap_model_tier_for_subscription(tier: str | None, model_tier: str | ModelTier) -> str:
    """Free tối đa `mid`; Premium/Ultra giữ nguyên (kể cả `large`)."""
    tier_norm = normalize_tier(tier)
    current = model_tier.value if isinstance(model_tier, ModelTier) else str(model_tier)

    if tier_norm == "Free" and current == ModelTier.LARGE.value:
        return ModelTier.MID.value
    return current


def ensure_commerce_model_tier(subscription_tier: str | None, model_tier: str | ModelTier) -> str:
    """Premium/Ultra commerce cần tools → không để kẹt `small`."""
    capped = cap_model_tier_for_subscription(subscription_tier, model_tier)
    if commerce_allowed(subscription_tier) and capped == ModelTier.SMALL.value:
        return ModelTier.MID.value
    return capped


def token_budget_for_subscription(tier: str | None) -> int:
    s = get_settings()
    tier_norm = normalize_tier(tier)
    if tier_norm == "Ultra":
        return s.ultra_token_budget
    if tier_norm == "Premium":
        return s.premium_token_budget
    return s.default_token_budget
