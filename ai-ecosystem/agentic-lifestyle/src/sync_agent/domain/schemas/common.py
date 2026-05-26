"""Shared base fields from Libs.Shared base entities."""

from datetime import date, datetime
from decimal import Decimal
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel

# C# API may return enums as int or PascalCase string — serializers accept both at parse time.
DecimalField = Annotated[Decimal, Field(json_schema_extra={"csharp_type": "decimal"})]


class StrictModel(BaseModel):
    """Reject unknown JSON keys (prevents hallucinated fields in JIT context)."""

    model_config = ConfigDict(
        extra="forbid",
        populate_by_name=True,
        alias_generator=to_camel,
        use_enum_values=False,
    )


class AuditableEntityFields(StrictModel):
    """Maps Libs.Shared BaseAuditableEntity (PostgreSQL services)."""

    id: UUID
    created_at: datetime
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class MongoEntityFields(StrictModel):
    """Maps Libs.Shared BaseMongoEntity (MongoDB services)."""

    id: UUID
    created_at: datetime
    updated_at: datetime | None = None


# Re-export for schema modules
DateOnly = date
