"""
Deterministic nutrition guardrails — Python-only, không tin LLM tuân thủ 100%.

Checks AllergyItem.allergen_name and dislikedFoods against spoken_response.
"""

from __future__ import annotations

import re
import unicodedata

from sync_agent.core.exceptions import GuardrailViolationError
from sync_agent.domain.schemas.agent.jit_context import JitContext
from sync_agent.domain.schemas.iam.allergy_item import AllergyItem


def _normalize(text: str) -> str:
    lowered = text.casefold()
    # Strip accents for fuzzy match (đậu phộng vs dau phong)
    normalized = unicodedata.normalize("NFD", lowered)
    return "".join(c for c in normalized if unicodedata.category(c) != "Mn")


# Terms that indicate the model is warning away from an item, not recommending it.
_AVOIDANCE_PREFIXES = (
    "tranh",
    "khong an",
    "khong dung",
    "khong nen",
    "ne ",
    "avoid",
    "without",
    "allergen free",
    "allergy free",
    "free from",
    "stay away",
    "do not eat",
    "dont eat",
)


def _find_term_span(haystack_normalized: str, term: str) -> tuple[int, int] | None:
    needle = _normalize(term.strip())
    if len(needle) < 2:
        return None
    match = re.search(rf"\b{re.escape(needle)}\b", haystack_normalized)
    if match:
        return match.start(), match.end()
    idx = haystack_normalized.find(needle)
    if idx >= 0:
        return idx, idx + len(needle)
    return None


def _is_avoidance_context(haystack_normalized: str, start: int) -> bool:
    """True when text immediately before the term signals warning/avoidance."""
    window = haystack_normalized[max(0, start - 48) : start]
    return any(prefix in window for prefix in _AVOIDANCE_PREFIXES)


def _contains_term(haystack_normalized: str, term: str) -> bool:
    span = _find_term_span(haystack_normalized, term)
    if span is None:
        return False
    start, _ = span
    if _is_avoidance_context(haystack_normalized, start):
        return False
    return True


def validate_nutrition_response(
    spoken_response: str,
    jit_context: JitContext | None,
) -> list[str]:
    """
    Return list of violation messages (empty if safe).
    """
    violations: list[str] = []
    if not spoken_response.strip():
        violations.append("spoken_response is empty")
        return violations

    normalized_response = _normalize(spoken_response)
    pref = jit_context.user_preference if jit_context else None

    if pref and pref.allergies:
        for item in pref.allergies:
            if _allergy_violates(item, normalized_response):
                violations.append(
                    f"spoken_response mentions allergen '{item.allergen_name}'"
                )

    if pref and pref.disliked_foods:
        for food in pref.disliked_foods:
            if food and _contains_term(normalized_response, food):
                violations.append(f"spoken_response mentions disliked food '{food}'")

    return violations


def _allergy_violates(item: AllergyItem, normalized_response: str) -> bool:
    if _contains_term(normalized_response, item.allergen_name):
        return True
    if item.notes and _contains_term(normalized_response, item.notes):
        return True
    return False


def assert_nutrition_response_safe(
    spoken_response: str,
    jit_context: JitContext | None,
) -> None:
    """Raise GuardrailViolationError if unsafe — used to trigger graph retry."""
    violations = validate_nutrition_response(spoken_response, jit_context)
    if violations:
        raise GuardrailViolationError(
            "Nutrition guardrail failed",
            violations=violations,
        )
