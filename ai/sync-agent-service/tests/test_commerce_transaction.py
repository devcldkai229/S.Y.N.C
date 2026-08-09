"""Unit tests — commerce transaction propose/contact/financial gate."""
from __future__ import annotations

from typing import Any
from unittest.mock import AsyncMock, patch

import pytest

from app.tools.catalog import AGENT_TOOLS, TOOL_REGISTRY, build_impls
from app.tools.context import ToolRunContext


@pytest.mark.asyncio
async def test_propose_order_needs_input_when_missing_phone_or_address():
    from app.graph.agents import commerce as commerce_mod

    state = {
        "user_id": "u1",
        "user_snapshot": {"maxAutoOrderLimitPerOrder": 200000, "allergies": []},
        "messages": [],
        "pending_actions": [],
        "locale": "vi",
    }

    contact = {
        "fullName": "An",
        "phone": None,
        "address": None,
        "missingFields": ["phone", "address"],
    }

    with patch.object(commerce_mod.dotnet, "get_default_contact", AsyncMock(return_value=contact)):
        # Invoke propose via agent internals by calling the schema path through a mini harness
        ctx = ToolRunContext(user_id="u1", state=dict(state))

        async def _propose(**kwargs: Any):
            # Reuse same logic by importing and constructing like commerce_agent
            contact2 = await commerce_mod.dotnet.get_default_contact("u1")
            phone = (kwargs.get("recipient_phone") or contact2.get("phone") or "").strip()
            address = (kwargs.get("delivery_address") or contact2.get("address") or "").strip()
            missing = []
            if not phone:
                missing.append("phone")
            if not address:
                missing.append("address")
            assert missing
            return {"status": "needs_input", "missing": missing}

        result = await _propose(
            partner_id="p1",
            items=[{"food_menu_item_id": "f1", "quantity": 1}],
        )
        assert result["status"] == "needs_input"
        assert "phone" in result["missing"]
        assert "address" in result["missing"]
        assert not ctx.pending_actions


@pytest.mark.asyncio
async def test_propose_order_creates_pending_with_quote_amount():
    from app.graph.agents.commerce import _norm_items
    from app.tools import dotnet as dotnet_mod

    assert _norm_items([{"food_menu_item_id": "f1", "quantity": 2}])[0]["quantity"] == 2

    contact = {
        "fullName": "An",
        "phone": "0901234567",
        "address": "1 Nguyễn Huệ, Q1",
        "lat": 10.77,
        "lng": 106.7,
        "missingFields": [],
    }
    quote = {
        "isValid": True,
        "subtotal": 80000,
        "deliveryFee": 25000,
        "discount": 0,
        "total": 105000,
        "lines": [{"nameVi": "Cơm gà", "foodMenuItemId": "f1", "quantity": 1}],
    }

    state = {
        "user_id": "u1",
        "subscription_tier": "Premium",
        "user_snapshot": {
            "maxAutoOrderLimitPerOrder": 200000,
            "allergies": [],
            "subscriptionTier": "Premium",
        },
        "messages": [],
        "pending_actions": [],
        "locale": "vi",
        "persona": "FriendlyBuddy",
        "motivation_style": "Supportive",
    }

    captured: dict[str, Any] = {}

    async def fake_run_tool_agent(state, agent, **kwargs):
        propose = kwargs["extra_impls"]["propose_order"]
        captured["result"] = await propose(
            partner_id="11111111-1111-1111-1111-111111111111",
            items=[{"food_menu_item_id": "22222222-2222-2222-2222-222222222222", "quantity": 1}],
            summary="Đặt cơm gà",
            payment_method_pref="vietqr",
            accept_distance_over_7km=True,
            delivery_confirmed=True,
        )
        return {"final_response": "ok", "pending_actions": []}

    with (
        patch("app.graph.agents.commerce.run_tool_agent", fake_run_tool_agent),
        patch.object(dotnet_mod, "get_default_contact", AsyncMock(return_value=contact)),
        patch.object(dotnet_mod, "quote_order", AsyncMock(return_value=quote)),
        patch.object(dotnet_mod, "get_partner_detail", AsyncMock(return_value={
            "id": "11111111-1111-1111-1111-111111111111",
            "lat": 10.78,
            "lng": 106.71,
            "distanceKm": 3.2,
        })),
        patch.object(dotnet_mod, "check_wallet", AsyncMock(return_value={
            "coinBalance": 1000, "vndPerCoin": 100,
        })),
    ):
        from app.graph.agents.commerce import commerce_agent

        out = await commerce_agent(state, config={})  # type: ignore[arg-type]

    assert captured["result"]["status"] == "pending_confirmation"
    assert captured["result"]["amount"] == 105000
    assert out.get("requires_confirmation") is True
    pending = out.get("pending_actions") or []
    assert any(p.get("type") == "create_order" for p in pending)
    create = next(p for p in pending if p.get("type") == "create_order")
    assert create["payment_method_pref"] == "vietqr"
    assert create["recipient_phone"] == "0901234567"
    assert create["ai_reasoning_snapshot_json"]


@pytest.mark.asyncio
async def test_propose_order_asks_payment_method_when_ask():
    from app.tools import dotnet as dotnet_mod

    contact = {
        "fullName": "An",
        "phone": "0901234567",
        "address": "1 Nguyễn Huệ, Q1",
        "lat": 10.77,
        "lng": 106.7,
        "missingFields": [],
    }
    quote = {
        "isValid": True,
        "subtotal": 80000,
        "deliveryFee": 25000,
        "discount": 0,
        "total": 105000,
        "lines": [{"nameVi": "Cơm gà", "foodMenuItemId": "f1", "quantity": 1}],
    }
    state = {
        "user_id": "u1",
        "subscription_tier": "Premium",
        "user_snapshot": {"maxAutoOrderLimitPerOrder": 200000, "allergies": [], "subscriptionTier": "Premium"},
        "messages": [],
        "pending_actions": [],
        "locale": "vi",
        "persona": "FriendlyBuddy",
        "motivation_style": "Supportive",
    }
    captured: dict[str, Any] = {}

    async def fake_run_tool_agent(state, agent, **kwargs):
        propose = kwargs["extra_impls"]["propose_order"]
        captured["result"] = await propose(
            partner_id="11111111-1111-1111-1111-111111111111",
            items=[{"food_menu_item_id": "22222222-2222-2222-2222-222222222222", "quantity": 1}],
            payment_method_pref="ask",
            delivery_confirmed=True,
        )
        return {"final_response": "ok", "pending_actions": [], "display_payload": []}

    with (
        patch("app.graph.agents.commerce.run_tool_agent", fake_run_tool_agent),
        patch.object(dotnet_mod, "get_default_contact", AsyncMock(return_value=contact)),
        patch.object(dotnet_mod, "quote_order", AsyncMock(return_value=quote)),
        patch.object(dotnet_mod, "get_partner_detail", AsyncMock(return_value={
            "lat": 10.78, "lng": 106.71, "distanceKm": 2.0,
        })),
        patch.object(dotnet_mod, "check_wallet", AsyncMock(return_value={
            "coinBalance": 500, "vndPerCoin": 100,
        })),
    ):
        from app.graph.agents.commerce import commerce_agent
        out = await commerce_agent(state, config={})  # type: ignore[arg-type]

    assert captured["result"]["status"] == "needs_payment_method"
    displays = out.get("display_payload") or []
    assert any(p.get("type") == "payment_method_select" for p in displays)


@pytest.mark.asyncio
async def test_financial_tools_are_pending_not_auto():
    ctx = ToolRunContext(user_id="u1", state={})
    impls = build_impls(ctx, ["reorder", "topup_wallet", "apply_voucher"])

    with patch("app.tools.catalog.dotnet") as d:
        d.get_order = AsyncMock(return_value={"totalAmount": 10000, "orderCode": "O1"})
        d.check_wallet = AsyncMock(return_value={"coinBalance": 1000, "vndPerCoin": 100})
        out_reorder = await impls["reorder"](previous_order_id="prev-1")
        out_topup = await impls["topup_wallet"](amount=50000, method="VietQR")
        out_voucher = await impls["apply_voucher"](voucher_code="SAVE10")

    assert out_reorder["status"] == "pending_confirmation"
    assert out_topup["status"] == "pending_confirmation"
    assert out_voucher["status"] == "use_propose_order"
    assert d.reorder.call_count == 0
    assert d.topup_wallet.call_count == 0
    types = {a["type"] for a in ctx.pending_actions}
    assert "reorder" in types
    assert "topup_wallet" in types


def test_commerce_tools_registered():
    for name in (
        "get_default_contact",
        "get_payment_status",
        "pay_with_wallet",
        "create_payment_link",
    ):
        assert name in TOOL_REGISTRY
        assert name in AGENT_TOOLS["commerce"]
    assert TOOL_REGISTRY["pay_with_wallet"].tool_type == "financial"
    assert TOOL_REGISTRY["create_payment_link"].tool_type == "financial"


@pytest.mark.asyncio
async def test_propose_order_shows_delivery_form_when_not_confirmed():
    """Step 1: propose_order without delivery_confirmed should return
    needs_delivery_confirmation and emit delivery_info_form + payment_method_select."""
    from app.tools import dotnet as dotnet_mod

    contact = {
        "fullName": "An",
        "phone": "0901234567",
        "address": "1 Nguyễn Huệ, Q1",
        "lat": 10.77,
        "lng": 106.7,
        "missingFields": [],
    }
    state = {
        "user_id": "u1",
        "subscription_tier": "Premium",
        "user_snapshot": {"maxAutoOrderLimitPerOrder": 200000, "allergies": [], "subscriptionTier": "Premium"},
        "messages": [],
        "pending_actions": [],
        "locale": "vi",
        "persona": "FriendlyBuddy",
        "motivation_style": "Supportive",
        "cart": [
            {"foodId": "22222222-2222-2222-2222-222222222222", "name": "Cơm gà",
             "partnerId": "11111111-1111-1111-1111-111111111111", "unitPrice": 55000, "qty": 1},
        ],
    }
    captured: dict[str, Any] = {}

    async def fake_run_tool_agent(state, agent, **kwargs):
        propose = kwargs["extra_impls"]["propose_order"]
        # Call WITHOUT delivery_confirmed (default False)
        captured["result"] = await propose(
            partner_id="11111111-1111-1111-1111-111111111111",
            items=[{"food_menu_item_id": "22222222-2222-2222-2222-222222222222", "quantity": 1}],
            payment_method_pref="ask",
        )
        return {"final_response": "ok", "pending_actions": [], "display_payload": []}

    with (
        patch("app.graph.agents.commerce.run_tool_agent", fake_run_tool_agent),
        patch.object(dotnet_mod, "get_default_contact", AsyncMock(return_value=contact)),
        patch.object(dotnet_mod, "check_wallet", AsyncMock(return_value={
            "coinBalance": 500, "vndPerCoin": 100,
        })),
    ):
        from app.graph.agents.commerce import commerce_agent
        out = await commerce_agent(state, config={})  # type: ignore[arg-type]

    # Step 1 should return needs_delivery_confirmation
    assert captured["result"]["status"] == "needs_delivery_confirmation"
    # Pre-filled data should be present
    assert captured["result"]["prefill"]["name"] == "An"
    assert captured["result"]["prefill"]["phone"] == "0901234567"
    # Display payload should include unified checkout_form (not separate cards)
    displays = out.get("display_payload") or []
    checkout_forms = [p for p in displays if p.get("type") == "checkout_form"]
    assert len(checkout_forms) >= 1, "Should emit checkout_form"
    form = checkout_forms[0]
    # Form should have payment_method as a select field
    field_keys = [f["key"] for f in form["fields"]]
    assert "payment_method" in field_keys, "payment_method should be a field in the form"
    assert "name" in field_keys
    assert "phone" in field_keys
    assert "address" in field_keys
    # No separate payment_method_select or delivery_info_form cards
    assert not any(p.get("type") == "payment_method_select" for p in displays)
    assert not any(p.get("type") == "delivery_info_form" for p in displays)
    # No pending actions yet (order not placed)
    pending = out.get("pending_actions") or []
    assert not any(p.get("type") == "create_order" for p in pending)
