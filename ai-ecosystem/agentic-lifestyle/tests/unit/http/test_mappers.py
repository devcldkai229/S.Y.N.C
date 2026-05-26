from datetime import date, datetime, timezone
from uuid import UUID

from sync_agent.infrastructure.http.api_dtos import (
    AccountPreferencesApiDto,
    BiometricProfileApiDto,
    PersonalizedRoadmapApiDto,
)
from sync_agent.infrastructure.http.mappers import (
    map_biometric_api_to_domain,
    map_preferences_api_to_domain,
    map_roadmap_api_to_domain,
    pick_active_roadmap,
)


def test_map_biometric_api_to_domain() -> None:
    uid = UUID("22222222-2222-2222-2222-222222222222")
    dto = BiometricProfileApiDto.model_validate(
        {
            "userId": str(uid),
            "gender": "Male",
            "dateOfBirth": "1990-01-01",
            "heightCm": 175,
            "currentWeightKg": 70,
            "targetWeightKg": 65,
            "fitnessGoal": "LoseFat",
            "activityLevel": "ModeratelyActive",
            "fitnessExperienceLevel": "Intermediate",
            "workoutLocationPreference": "Gym",
            "baseTDEE": 2000,
            "bmr": 1600,
        }
    )
    domain = map_biometric_api_to_domain(dto)
    assert domain.user_id == uid
    assert domain.base_tdee == 2000


def test_map_preferences_with_allergy_objects() -> None:
    uid = UUID("33333333-3333-3333-3333-333333333333")
    dto = AccountPreferencesApiDto.model_validate(
        {
            "isConfigured": True,
            "allergies": [{"allergenName": "Peanut", "severity": "High", "notes": None}],
            "favoriteFoods": [],
            "dislikedFoods": [],
            "agentPersona": "FriendlyBuddy",
            "motivationStyle": "Supportive",
            "autoOrderEnabled": False,
            "dataSharingConsent": True,
            "marketingConsent": False,
        }
    )
    pref = map_preferences_api_to_domain(dto, user_id=uid)
    assert pref.allergies is not None
    assert pref.allergies[0].allergen_name == "Peanut"


def test_pick_active_roadmap() -> None:
    base = {
        "userId": "11111111-1111-1111-1111-111111111111",
        "roadmapName": "A",
        "fitnessGoal": "x",
        "currentPhase": "p",
        "startDate": "2026-01-01T00:00:00+00:00",
        "currentWeightKg": 70,
        "targetWeightKg": 65,
        "initialFatPercentage": 20,
        "targetFatPercentage": 15,
        "adaptiveAiEnabled": True,
        "allowAiReschedule": True,
        "allowAiIntensityAdjustment": True,
        "allowAiRecoveryDeload": False,
        "createdAt": "2026-01-01T00:00:00+00:00",
    }
    paused = PersonalizedRoadmapApiDto.model_validate(
        {**base, "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", "roadmapStatus": "Paused"}
    )
    active = PersonalizedRoadmapApiDto.model_validate(
        {**base, "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "roadmapStatus": "Active"}
    )
    chosen = pick_active_roadmap([paused, active])
    assert chosen is not None
    assert chosen.id == active.id
