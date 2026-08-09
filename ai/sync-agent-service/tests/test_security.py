"""JWT tier claim + subscription gating tests."""
from __future__ import annotations

import base64
import builtins
import json

import pytest
from fastapi import HTTPException

from app.api import security
from app.config import ModelTier
from app.graph.subscription_gating import cap_model_tier_for_subscription, normalize_tier, token_budget_for_subscription


def _make_dev_token(payload: dict) -> str:
    body = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")
    return f"hdr.{body}.sig"


def test_auth_context_reads_tier_claim(monkeypatch):
    monkeypatch.setattr(security.get_settings(), "environment", "development")
    real_import = builtins.__import__

    def _block_jwt(name, globals=None, locals=None, fromlist=(), level=0):
        if name == "jwt":
            raise ModuleNotFoundError("jwt")
        return real_import(name, globals, locals, fromlist, level)

    monkeypatch.setattr(builtins, "__import__", _block_jwt)

    free_token = _make_dev_token({"sub": "user-free", "tier": "Free", "exp": 9999999999})
    premium_token = _make_dev_token({"sub": "user-prem", "tier": "Premium", "exp": 9999999999})

    free_ctx = security.auth_from_header(f"Bearer {free_token}")
    premium_ctx = security.auth_from_header(f"Bearer {premium_token}")

    assert free_ctx.tier == "Free"
    assert premium_ctx.tier == "Premium"


def test_auth_defaults_tier_to_free_when_missing(monkeypatch):
    monkeypatch.setattr(security.get_settings(), "environment", "development")
    real_import = builtins.__import__

    def _block_jwt(name, globals=None, locals=None, fromlist=(), level=0):
        if name == "jwt":
            raise ModuleNotFoundError("jwt")
        return real_import(name, globals, locals, fromlist, level)

    monkeypatch.setattr(builtins, "__import__", _block_jwt)
    token = _make_dev_token({"sub": "user-1", "exp": 9999999999})
    ctx = security.auth_from_header(f"Bearer {token}")
    assert ctx.tier == "Free"


def test_production_rejects_missing_pyjwt(monkeypatch):
    monkeypatch.setattr(security.get_settings(), "environment", "production")
    real_import = builtins.__import__

    def _block_jwt(name, globals=None, locals=None, fromlist=(), level=0):
        if name == "jwt":
            raise ModuleNotFoundError("jwt")
        return real_import(name, globals, locals, fromlist, level)

    monkeypatch.setattr(builtins, "__import__", _block_jwt)
    with pytest.raises(HTTPException) as exc:
        security._decode("eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1In0.sig")
    assert exc.value.status_code == 500


def test_dev_allows_fallback_decode_without_pyjwt(monkeypatch):
    monkeypatch.setattr(security.get_settings(), "environment", "development")
    real_import = builtins.__import__

    def _block_jwt(name, globals=None, locals=None, fromlist=(), level=0):
        if name == "jwt":
            raise ModuleNotFoundError("jwt")
        return real_import(name, globals, locals, fromlist, level)

    monkeypatch.setattr(builtins, "__import__", _block_jwt)
    token = _make_dev_token({"sub": "user-1", "exp": 9999999999})
    claims = security._decode(token)
    assert claims["sub"] == "user-1"


def test_free_caps_large_model_to_mid():
    assert cap_model_tier_for_subscription("Free", ModelTier.LARGE) == ModelTier.MID.value
    assert cap_model_tier_for_subscription("Free", ModelTier.MID) == ModelTier.MID.value


def test_premium_allows_large_model():
    assert cap_model_tier_for_subscription("Premium", ModelTier.LARGE) == ModelTier.LARGE.value


def test_token_budget_by_tier(monkeypatch):
    monkeypatch.setattr(security.get_settings(), "default_token_budget", 8000)
    monkeypatch.setattr(security.get_settings(), "premium_token_budget", 12000)
    monkeypatch.setattr(security.get_settings(), "ultra_token_budget", 16000)
    assert token_budget_for_subscription("Free") == 8000
    assert token_budget_for_subscription("Premium") == 12000
    assert token_budget_for_subscription("Ultra") == 16000


def test_normalize_tier_aliases():
    assert normalize_tier("pro") == "pro"  # unknown stays as-is; JWT uses Premium
    assert normalize_tier("premium") == "Premium"
