"""Roadmap.Domain.Models.PersonalizedRoadmap + BaseMongoEntity."""

from datetime import datetime
from uuid import UUID

from pydantic import field_validator

from sync_agent.domain.schemas.common import DecimalField, MongoEntityFields
from sync_agent.domain.schemas.enums import RoadmapStatus
from sync_agent.domain.schemas.enums._coerce import coerce_int_enum


class PersonalizedRoadmap(MongoEntityFields):
    """Maps C# PersonalizedRoadmap (RoadmapStatus from Libs.Shared.Enums)."""

    user_id: UUID
    roadmap_name: str
    fitness_goal: str
    current_phase: str
    start_date: datetime
    expected_end_date: datetime | None = None
    current_weight_kg: DecimalField
    target_weight_kg: DecimalField
    initial_fat_percentage: DecimalField
    target_fat_percentage: DecimalField
    adaptive_ai_enabled: bool
    allow_ai_reschedule: bool
    allow_ai_intensity_adjustment: bool
    allow_ai_recovery_deload: bool
    roadmap_status: RoadmapStatus

    @field_validator("roadmap_status", mode="before")
    @classmethod
    def _coerce_roadmap_status(cls, value: object) -> RoadmapStatus:
        return coerce_int_enum(RoadmapStatus, value)
