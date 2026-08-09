"""Tests for evaluate_food_fit and markdown image strip."""
from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest

from app.api.main import _strip_markdown_for_chat
from app.tools.context import ToolRunContext
from app.tools.local import evaluate_food_fit


def test_strip_markdown_removes_images_and_bold():
    raw = (
        "Đây là món **ức gà**\n"
        "![Hình ảnh](https://images.unsplash.com/photo-1)\n"
        "Giá 55.000đ"
    )
    out = _strip_markdown_for_chat(raw)
    assert "**" not in out
    assert "![" not in out
    assert "images.unsplash.com" not in out
    assert "ức gà" in out
    assert "55.000đ" in out


@pytest.mark.asyncio
async def test_evaluate_food_fit_uses_tools_not_invented():
    ctx = ToolRunContext(
        user_id="u1",
        state={
            "user_snapshot": {
                "fitnessGoal": "LoseFat",
                "baseTDEE": 2000,
                "allergies": [],
            },
            "user_timezone": "Asia/Ho_Chi_Minh",
        },
    )

    food = {
        "id": "food-1",
        "nameVi": "Cơm ức gà rau củ",
        "calories": 460,
        "proteinG": 36,
        "carbG": 50,
        "fatG": 10,
    }
    targets = {"dailyCalorieTarget": 2000, "proteinG": 120, "carbG": 180, "fatG": 60}
    summary = {"totalCalories": 800, "totalProteinG": 40, "totalCarbG": 90, "totalFatG": 20}

    with (
        patch("app.tools.local.dotnet.get_food_detail", AsyncMock(return_value=food)),
        patch("app.tools.local.dotnet.get_nutrition_targets", AsyncMock(return_value=targets)),
        patch("app.tools.local.dotnet.get_daily_summary", AsyncMock(return_value=summary)),
    ):
        result = await evaluate_food_fit(ctx, food_menu_item_id="food-1", days=3)

    assert result["status"] == "ok"
    assert result["food"]["calories"] == 460
    assert result["verdict"] in ("fit", "borderline", "not_fit")
    assert result["reasons"]
    assert any(p.get("type") == "food_detail" for p in ctx.display_payload)


@pytest.mark.asyncio
async def test_evaluate_food_fit_missing_id():
    ctx = ToolRunContext(user_id="u1", state={})
    result = await evaluate_food_fit(ctx, food_menu_item_id="")
    assert "error" in result
