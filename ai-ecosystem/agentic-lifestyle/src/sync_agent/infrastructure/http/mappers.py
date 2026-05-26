"""
Map C# API DTOs → domain Pydantic entities (strict domain fields).

Audit fields missing from slim API DTOs are synthesized so domain validators pass;
downstream LLM prompts use business fields only.
"""

from datetime import datetime, timezone
from uuid import UUID, uuid4

from sync_agent.domain.schemas.enums import RoadmapStatus
from sync_agent.domain.schemas.enums._coerce import coerce_int_enum
from sync_agent.domain.schemas.iam.biometric_profile import BiometricProfile
from sync_agent.domain.schemas.iam.user_preference import UserPreference
from sync_agent.domain.schemas.roadmap.personalized_roadmap import PersonalizedRoadmap
from sync_agent.domain.schemas.roadmap.recovery_profile import RecoveryProfile
from sync_agent.infrastructure.http.api_dtos import (
    AccountPreferencesApiDto,
    BiometricProfileApiDto,
    PersonalizedRoadmapApiDto,
    RecoveryProfileApiDto,
)


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def map_biometric_api_to_domain(dto: BiometricProfileApiDto) -> BiometricProfile:
    """BiometricProfileDto → domain BiometricProfile."""
    now = _utc_now()
    payload = {
        "id": uuid4(),
        "createdAt": now.isoformat(),
        "updatedAt": None,
        "deletedAt": None,
        "userId": str(dto.user_id),
        "gender": dto.gender,
        "dateOfBirth": dto.date_of_birth.isoformat(),
        "heightCm": dto.height_cm,
        "currentWeightKg": dto.current_weight_kg,
        "targetWeightKg": dto.target_weight_kg,
        "currentBodyFatPercentage": dto.current_body_fat_percentage,
        "goalBodyFatPercentage": dto.goal_body_fat_percentage,
        "muscleMassKg": dto.muscle_mass_kg,
        "fitnessGoal": dto.fitness_goal,
        "activityLevel": dto.activity_level,
        "fitnessExperienceLevel": dto.fitness_experience_level,
        "workoutLocationPreference": dto.workout_location_preference,
        "baseTDEE": dto.base_tdee,
        "bmr": dto.bmr,
        "dailyProteinTargetGram": dto.daily_protein_target_gram,
        "dailyCarbTargetGram": dto.daily_carb_target_gram,
        "dailyFatTargetGram": dto.daily_fat_target_gram,
        "injuries": dto.injuries,
        "medications": dto.medications,
    }
    return BiometricProfile.model_validate(payload)


def map_preferences_api_to_domain(
    dto: AccountPreferencesApiDto,
    *,
    user_id: UUID,
    entity_id: UUID | None = None,
) -> UserPreference:
    """AccountPreferencesDto + user_id → domain UserPreference."""
    now = _utc_now()
    payload = {
        "id": str(entity_id or uuid4()),
        "createdAt": now.isoformat(),
        "updatedAt": None,
        "deletedAt": None,
        "userId": str(user_id),
        "allergies": [a.model_dump(by_alias=True) for a in dto.allergies],
        "favoriteFoods": list(dto.favorite_foods),
        "dislikedFoods": list(dto.disliked_foods),
        "agentPersona": dto.agent_persona,
        "motivationStyle": dto.motivation_style,
        "autoOrderEnabled": dto.auto_order_enabled,
        "maxAutoOrderLimitDaily": dto.max_auto_order_limit_daily,
        "maxAutoOrderLimitPerOrder": dto.max_auto_order_limit_per_order,
        "dataSharingConsent": dto.data_sharing_consent,
        "marketingConsent": dto.marketing_consent,
    }
    return UserPreference.model_validate(payload)


def map_roadmap_api_to_domain(dto: PersonalizedRoadmapApiDto) -> PersonalizedRoadmap:
    """PersonalizedRoadmapDto maps 1:1 with domain (+ mongo base fields)."""
    payload = {
        "id": str(dto.id),
        "createdAt": dto.created_at.isoformat(),
        "updatedAt": dto.updated_at.isoformat() if dto.updated_at else None,
        "userId": str(dto.user_id),
        "roadmapName": dto.roadmap_name,
        "fitnessGoal": dto.fitness_goal,
        "currentPhase": dto.current_phase,
        "startDate": dto.start_date.isoformat(),
        "expectedEndDate": dto.expected_end_date.isoformat() if dto.expected_end_date else None,
        "currentWeightKg": dto.current_weight_kg,
        "targetWeightKg": dto.target_weight_kg,
        "initialFatPercentage": dto.initial_fat_percentage,
        "targetFatPercentage": dto.target_fat_percentage,
        "adaptiveAiEnabled": dto.adaptive_ai_enabled,
        "allowAiReschedule": dto.allow_ai_reschedule,
        "allowAiIntensityAdjustment": dto.allow_ai_intensity_adjustment,
        "allowAiRecoveryDeload": dto.allow_ai_recovery_deload,
        "roadmapStatus": dto.roadmap_status,
    }
    return PersonalizedRoadmap.model_validate(payload)


def map_recovery_api_to_domain(dto: RecoveryProfileApiDto) -> RecoveryProfile:
    payload = {
        "id": str(dto.id),
        "createdAt": dto.created_at.isoformat(),
        "updatedAt": dto.updated_at.isoformat() if dto.updated_at else None,
        "userId": str(dto.user_id),
        "currentRecoveryScore": dto.current_recovery_score,
        "fatigueLevel": dto.fatigue_level,
        "sleepRecoveryScore": dto.sleep_recovery_score,
        "muscleSorenessScore": dto.muscle_soreness_score,
        "cnsFatigueScore": dto.cns_fatigue_score,
        "recommendedTrainingIntensity": dto.recommended_training_intensity,
        "recommendedWorkoutDuration": dto.recommended_workout_duration,
    }
    return RecoveryProfile.model_validate(payload)


def pick_active_roadmap(roadmaps: list[PersonalizedRoadmapApiDto]) -> PersonalizedRoadmapApiDto | None:
    """Prefer Active roadmap; fallback to most recently created."""
    if not roadmaps:
        return None
    for item in roadmaps:
        status = (
            item.roadmap_status
            if isinstance(item.roadmap_status, RoadmapStatus)
            else coerce_int_enum(RoadmapStatus, item.roadmap_status)
        )
        if status == RoadmapStatus.Active:
            return item
    return max(roadmaps, key=lambda r: r.created_at)


def pick_latest_recovery(profiles: list[RecoveryProfileApiDto]) -> RecoveryProfileApiDto | None:
    if not profiles:
        return None
    return max(profiles, key=lambda p: p.created_at)
