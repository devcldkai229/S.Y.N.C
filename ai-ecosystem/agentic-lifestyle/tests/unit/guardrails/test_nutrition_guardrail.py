from decimal import Decimal
from datetime import date, datetime, timezone
from uuid import UUID

import pytest

from sync_agent.application.guardrails.nutrition_guardrail import (
    assert_nutrition_response_safe,
    validate_nutrition_response,
)
from sync_agent.core.exceptions import GuardrailViolationError
from sync_agent.domain.schemas.agent.jit_context import JitContext
from sync_agent.domain.schemas.iam.allergy_item import AllergyItem
from sync_agent.domain.schemas.iam.user_preference import UserPreference


def _preference(*, allergies=None, disliked=None) -> UserPreference:
    now = datetime.now(timezone.utc)
    uid = UUID("11111111-1111-1111-1111-111111111111")
    return UserPreference.model_validate(
        {
            "id": str(uid),
            "createdAt": now.isoformat(),
            "userId": str(uid),
            "allergies": allergies or [],
            "favoriteFoods": [],
            "dislikedFoods": disliked or [],
            "agentPersona": "FriendlyBuddy",
            "motivationStyle": "Supportive",
            "autoOrderEnabled": False,
            "dataSharingConsent": True,
            "marketingConsent": False,
        }
    )


def test_safe_response_no_violations() -> None:
    ctx = JitContext(
        user_preference=_preference(
            allergies=[AllergyItem(allergen_name="Đậu phộng", severity="High", notes=None)],
            disliked=["Cà rốt"],
        )
    )
    violations = validate_nutrition_response(
        "Tối nay ăn cơm gà và rau xanh, tránh đậu phộng và cà rốt nhé.",
        ctx,
    )
    assert violations == []


def test_safe_response_without_allergen_mentions() -> None:
    ctx = JitContext(
        user_preference=_preference(
            allergies=[AllergyItem(allergen_name="Đậu phộng", severity="High", notes=None)],
        )
    )
    violations = validate_nutrition_response(
        "Tối nay ăn cơm gà và rau luộc, nhẹ bụng và đủ protein.",
        ctx,
    )
    assert violations == []


def test_detects_allergen_in_spoken_response() -> None:
    ctx = JitContext(
        user_preference=_preference(
            allergies=[AllergyItem(allergen_name="Đậu phộng", severity="High", notes=None)],
        )
    )
    violations = validate_nutrition_response(
        "Bạn thử món gỏi cuốn đậu phộng cho nhẹ bụng.",
        ctx,
    )
    assert any("Đậu phộng" in v or "đậu phộng" in v for v in violations)


def test_detects_disliked_food() -> None:
    ctx = JitContext(user_preference=_preference(disliked=["cà rốt"]))
    violations = validate_nutrition_response("Món có cà rốt băm nhỏ rất ngon.", ctx)
    assert len(violations) >= 1


def test_assert_raises_guardrail_violation() -> None:
    ctx = JitContext(
        user_preference=_preference(
            allergies=[AllergyItem(allergen_name="Tôm", severity=None, notes=None)],
        )
    )
    with pytest.raises(GuardrailViolationError) as exc:
        assert_nutrition_response_safe("Hải sản tôm hùm tươi ngon.", ctx)
    assert exc.value.violations
