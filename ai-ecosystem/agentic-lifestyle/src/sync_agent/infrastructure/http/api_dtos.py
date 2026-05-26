"""
C# API response DTOs (HTTP layer only).

These mirror Application-layer DTOs from .NET — NOT full domain entities.
Mappers convert into domain.schemas.* models.
"""

from datetime import date, datetime
from uuid import UUID

from pydantic import Field

from sync_agent.domain.schemas.common import StrictModel
from sync_agent.domain.schemas.iam.allergy_item import AllergyItem


class ApiEnvelope(StrictModel):
    success: bool
    message: str = ""
    data: object | None = None
    errors: object | None = None


class PaginationMeta(StrictModel):
    page_number: int = 1
    page_size: int = 10
    total_records: int = 0
    total_pages: int = 0
    has_previous_page: bool = False
    has_next_page: bool = False


class PagedEnvelope(ApiEnvelope):
    pagination: PaginationMeta = Field(default_factory=PaginationMeta)


class BiometricProfileApiDto(StrictModel):
    """Iam.Application.DTOs.BiometricProfileDto"""

    user_id: UUID
    gender: str | int
    date_of_birth: date
    height_cm: float
    current_weight_kg: float
    target_weight_kg: float
    current_body_fat_percentage: float | None = None
    goal_body_fat_percentage: float | None = None
    muscle_mass_kg: float | None = None
    fitness_goal: str | int
    activity_level: str | int
    fitness_experience_level: str | int
    workout_location_preference: str | int
    base_tdee: int = Field(validation_alias="baseTDEE")
    bmr: int
    daily_protein_target_gram: int | None = None
    daily_carb_target_gram: int | None = None
    daily_fat_target_gram: int | None = None
    injuries: list[str] | None = None
    medications: list[str] | None = None


class AccountPreferencesApiDto(StrictModel):
    """Iam.Application.DTOs.AccountPreferencesDto"""

    is_configured: bool
    allergies: list[AllergyItem]
    favorite_foods: list[str]
    disliked_foods: list[str]
    agent_persona: str | int
    motivation_style: str | int
    auto_order_enabled: bool
    max_auto_order_limit_daily: float | None = None
    max_auto_order_limit_per_order: float | None = None
    data_sharing_consent: bool
    marketing_consent: bool


class ProfileSettingsApiDto(StrictModel):
    """Iam.Application.DTOs.ProfileSettingsResponse (preferences slice used for JIT)."""

    user_id: UUID
    preferences: AccountPreferencesApiDto


class PersonalizedRoadmapApiDto(StrictModel):
    """Roadmap.Application.DTOs.PersonalizedRoadmapDto"""

    id: UUID
    user_id: UUID
    roadmap_name: str
    fitness_goal: str
    current_phase: str
    start_date: datetime
    expected_end_date: datetime | None = None
    current_weight_kg: float
    target_weight_kg: float
    initial_fat_percentage: float
    target_fat_percentage: float
    adaptive_ai_enabled: bool
    allow_ai_reschedule: bool
    allow_ai_intensity_adjustment: bool
    allow_ai_recovery_deload: bool
    roadmap_status: str | int
    created_at: datetime
    updated_at: datetime | None = None


class RecoveryProfileApiDto(StrictModel):
    """Roadmap.Application.DTOs.RecoveryProfileDto"""

    id: UUID
    user_id: UUID
    current_recovery_score: int
    fatigue_level: int
    sleep_recovery_score: int
    muscle_soreness_score: int
    cns_fatigue_score: int
    recommended_training_intensity: str
    recommended_workout_duration: int
    created_at: datetime
    updated_at: datetime | None = None
