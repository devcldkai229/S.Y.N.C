"""Integration contract tests — demo seed assertions + read-after-write.

Requires local .NET microservices and demo seed applied.

Run:
  set RUN_INTEGRATION=1
  pytest tests/integration/test_tool_contracts.py -v

Smoke connectivity only (no seed asserts):
  python -m tests.integration.audit_tools

Audit + contracts:
  python -m tests.integration.audit_tools --assert-contracts
"""
from __future__ import annotations

import pytest

from tests.integration.demo_contracts import (
    EXPECT_ROADMAP_ID,
    SEED_RICE_FOOD_ID,
    validate_contract,
)
from tests.integration.integration_harness import invoke_tool

pytestmark = [pytest.mark.integration, pytest.mark.asyncio]

# tool_name, kwargs for invoke_tool
SEED_READ_CASES = [
    ("get_gamification_status", {}),
    ("get_active_roadmap", {}),
    ("get_today_workout", {}),
    ("get_daily_summary", {}),
    ("check_wallet", {}),
    ("list_vouchers", {}),
    ("get_nutrition_targets", {}),
    ("get_recovery_status", {}),
    ("search_exercises", {"query": "push", "limit": 5}),
    ("search_food", {"query": "ức gà", "limit": 3}),
    ("search_partners", {"query": "kitchen"}),
    ("get_roadmap_sessions", {"roadmap_id": EXPECT_ROADMAP_ID}),
]


class TestDemoSeedReads:
    @pytest.mark.parametrize("tool_name,kwargs", SEED_READ_CASES)
    async def test_read_matches_demo_seed(self, demo_impls, tool_name, kwargs):
        result = await invoke_tool(demo_impls, tool_name, **kwargs)
        assert "error" not in result or not result["error"], result.get("error")
        errors = validate_contract(tool_name, result, kwargs=kwargs)
        assert errors == [], f"{tool_name} contract violations: {errors}"


class TestNutritionReadAfterWrite:
    async def test_log_water_increases_water_intake(self, demo_impls):
        before = await invoke_tool(demo_impls, "get_daily_summary")
        assert "error" not in before or not before["error"], before.get("error")

        delta = 50
        written = await invoke_tool(demo_impls, "log_water", amount_ml=delta)
        assert "error" not in written or not written["error"], written.get("error")

        after = await invoke_tool(demo_impls, "get_daily_summary")
        assert "error" not in after or not after["error"], after.get("error")

        w0 = before["waterIntakeMl"]
        assert written["waterIntakeMl"] == w0 + delta
        assert after["waterIntakeMl"] == w0 + delta
        assert after["consumedCalories"] == before["consumedCalories"]

    async def test_log_meal_increases_consumed_macros(self, demo_impls):
        before = await invoke_tool(demo_impls, "get_daily_summary")
        assert "error" not in before or not before["error"], before.get("error")

        meal = await invoke_tool(
            demo_impls,
            "log_meal",
            meal_type="Snack",
            items=[{"foodItemId": SEED_RICE_FOOD_ID, "quantityGram": 50}],
            notes="contract test",
        )
        assert "error" not in meal or not meal["error"], meal.get("error")

        after = await invoke_tool(demo_impls, "get_daily_summary")
        assert "error" not in after or not after["error"], after.get("error")

        assert after["mealsLoggedCount"] == before["mealsLoggedCount"] + 1
        assert after["consumedCalories"] > before["consumedCalories"]
        assert meal["totalCalories"] > 0


class TestRoadmapReadAfterWrite:
    async def test_update_roadmap_phase_readback(self, demo_impls):
        original = await invoke_tool(demo_impls, "get_active_roadmap")
        assert "error" not in original or not original["error"], original.get("error")
        roadmap_id = original["id"]
        original_phase = original.get("currentPhase") or "Foundation"

        try:
            patched = await invoke_tool(
                demo_impls,
                "update_roadmap",
                roadmap_id=roadmap_id,
                current_phase="ContractTestPhase",
            )
            assert "error" not in patched or not patched["error"], patched.get("error")

            reread = await invoke_tool(demo_impls, "get_active_roadmap")
            assert reread.get("currentPhase") == "ContractTestPhase"
        finally:
            await invoke_tool(
                demo_impls,
                "update_roadmap",
                roadmap_id=roadmap_id,
                current_phase=original_phase,
            )
