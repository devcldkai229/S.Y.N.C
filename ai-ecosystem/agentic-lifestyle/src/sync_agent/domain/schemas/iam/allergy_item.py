"""Iam.Domain.Models.AllergyItem — value object (record)."""

from sync_agent.domain.schemas.common import StrictModel


class AllergyItem(StrictModel):
    """Maps C#: sealed record AllergyItem(AllergenName, Severity?, Notes?)."""

    allergen_name: str
    severity: str | None = None
    notes: str | None = None
