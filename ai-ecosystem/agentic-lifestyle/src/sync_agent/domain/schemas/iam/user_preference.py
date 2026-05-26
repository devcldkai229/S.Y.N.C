"""Iam.Domain.Models.UserPreference + BaseAuditableEntity."""

from uuid import UUID

from pydantic import field_validator

from sync_agent.domain.schemas.common import AuditableEntityFields, DecimalField
from sync_agent.domain.schemas.enums import AgentPersona, MotivationStyle
from sync_agent.domain.schemas.enums._coerce import coerce_int_enum
from sync_agent.domain.schemas.iam.allergy_item import AllergyItem


class UserPreference(AuditableEntityFields):
    """
    Maps C# UserPreference (excludes navigation property User).
    Allergies: List<AllergyItem>? — each element is a structured object, not a string.
    """

    user_id: UUID
    allergies: list[AllergyItem] | None = None
    favorite_foods: list[str] | None = None
    disliked_foods: list[str] | None = None
    agent_persona: AgentPersona
    motivation_style: MotivationStyle
    auto_order_enabled: bool
    max_auto_order_limit_daily: DecimalField | None = None
    max_auto_order_limit_per_order: DecimalField | None = None
    data_sharing_consent: bool
    marketing_consent: bool

    @field_validator("agent_persona", "motivation_style", mode="before")
    @classmethod
    def _coerce_enums(cls, value: object, info):  # type: ignore[no-untyped-def]
        enum_map = {
            "agent_persona": AgentPersona,
            "motivation_style": MotivationStyle,
        }
        return coerce_int_enum(enum_map[info.field_name], value)
