"""Iam.Domain.Models.BiometricProfile + BaseAuditableEntity."""

from datetime import date
from uuid import UUID

from pydantic import AliasChoices, Field, field_validator

from sync_agent.domain.schemas.common import AuditableEntityFields, DateOnly, DecimalField, StrictModel
from sync_agent.domain.schemas.enums import (
    ActivityLevel,
    FitnessExperienceLevel,
    FitnessGoal,
    Gender,
    WorkoutLocationPreference,
)
from sync_agent.domain.schemas.enums._coerce import coerce_int_enum


class BiometricProfile(AuditableEntityFields):
    """
    Maps C# BiometricProfile (excludes navigation property User).
    Inherits Id, CreatedAt, UpdatedAt, DeletedAt from BaseAuditableEntity.
    """

    user_id: UUID
    gender: Gender
    date_of_birth: DateOnly
    height_cm: DecimalField
    current_weight_kg: DecimalField
    target_weight_kg: DecimalField
    current_body_fat_percentage: DecimalField | None = None
    goal_body_fat_percentage: DecimalField | None = None
    muscle_mass_kg: DecimalField | None = None
    fitness_goal: FitnessGoal
    activity_level: ActivityLevel
    fitness_experience_level: FitnessExperienceLevel
    workout_location_preference: WorkoutLocationPreference
    base_tdee: int = Field(validation_alias=AliasChoices("baseTDEE", "baseTdee"))
    bmr: int
    daily_protein_target_gram: int | None = None
    daily_carb_target_gram: int | None = None
    daily_fat_target_gram: int | None = None
    injuries: list[str] | None = None
    medications: list[str] | None = None

    @field_validator(
        "gender",
        "fitness_goal",
        "activity_level",
        "fitness_experience_level",
        "workout_location_preference",
        mode="before",
    )
    @classmethod
    def _coerce_enums(cls, value: object, info):  # type: ignore[no-untyped-def]
        enum_map = {
            "gender": Gender,
            "fitness_goal": FitnessGoal,
            "activity_level": ActivityLevel,
            "fitness_experience_level": FitnessExperienceLevel,
            "workout_location_preference": WorkoutLocationPreference,
        }
        enum_cls = enum_map[info.field_name]
        return coerce_int_enum(enum_cls, value)
