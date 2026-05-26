"""Validate Pydantic schemas mirror C# domain — extra fields rejected."""

from datetime import date, datetime, timezone
from decimal import Decimal
from uuid import UUID

import pytest

from sync_agent.domain.schemas import (
    AIContextProfile,
    AllergyItem,
    BiometricProfile,
    JitContext,
    LLMAgentOutput,
    PersonalizedRoadmap,
    RecoveryProfile,
    ToolCall,
    UserPreference,
)
from sync_agent.domain.schemas.enums import (
    ActivityLevel,
    AgentPersona,
    FitnessGoal,
    Gender,
    MotivationStyle,
    RoadmapStatus,
)


def _uuid() -> UUID:
    return UUID("11111111-1111-1111-1111-111111111111")


def _auditable_base() -> dict:
    return {
        "id": str(_uuid()),
        "createdAt": "2026-01-01T00:00:00+00:00",
        "updatedAt": None,
        "deletedAt": None,
    }


def _mongo_base() -> dict:
    return {
        "id": str(_uuid()),
        "createdAt": "2026-01-01T00:00:00+00:00",
        "updatedAt": None,
    }


class TestAllergyItem:
    def test_maps_csharp_record(self) -> None:
        item = AllergyItem.model_validate(
            {"allergenName": "Peanuts", "severity": "High", "notes": "EpiPen"}
        )
        assert item.allergen_name == "Peanuts"
        assert item.severity == "High"

    def test_rejects_extra_fields(self) -> None:
        with pytest.raises(ValueError):
            AllergyItem.model_validate(
                {"allergenName": "Milk", "severity": None, "notes": None, "foo": "bar"}
            )


class TestUserPreference:
    def test_allergies_as_object_list(self) -> None:
        payload = {
            **_auditable_base(),
            "userId": str(_uuid()),
            "allergies": [
                {"allergenName": "Shellfish", "severity": "Medium", "notes": None},
            ],
            "favoriteFoods": ["Phở"],
            "dislikedFoods": ["Cà rốt"],
            "agentPersona": "FriendlyBuddy",
            "motivationStyle": "Supportive",
            "autoOrderEnabled": False,
            "maxAutoOrderLimitDaily": None,
            "maxAutoOrderLimitPerOrder": None,
            "dataSharingConsent": True,
            "marketingConsent": False,
        }
        pref = UserPreference.model_validate(payload)
        assert pref.allergies is not None
        assert len(pref.allergies) == 1
        assert pref.allergies[0].allergen_name == "Shellfish"
        assert pref.agent_persona == AgentPersona.FriendlyBuddy

    def test_rejects_string_allergy(self) -> None:
        payload = {
            **_auditable_base(),
            "userId": str(_uuid()),
            "allergies": ["Peanuts"],
            "favoriteFoods": None,
            "dislikedFoods": None,
            "agentPersona": 1,
            "motivationStyle": 0,
            "autoOrderEnabled": False,
            "maxAutoOrderLimitDaily": None,
            "maxAutoOrderLimitPerOrder": None,
            "dataSharingConsent": True,
            "marketingConsent": False,
        }
        with pytest.raises(ValueError):
            UserPreference.model_validate(payload)


class TestBiometricProfile:
    def test_parses_camel_case_api_json(self) -> None:
        payload = {
            **_auditable_base(),
            "userId": str(_uuid()),
            "gender": "Male",
            "dateOfBirth": "1995-06-15",
            "heightCm": "175.5",
            "currentWeightKg": "72.0",
            "targetWeightKg": "68.0",
            "currentBodyFatPercentage": None,
            "goalBodyFatPercentage": None,
            "muscleMassKg": None,
            "fitnessGoal": "LoseFat",
            "activityLevel": "ModeratelyActive",
            "fitnessExperienceLevel": "Intermediate",
            "workoutLocationPreference": "Gym",
            "baseTDEE": 2200,
            "bmr": 1700,
            "dailyProteinTargetGram": 140,
            "dailyCarbTargetGram": 200,
            "dailyFatTargetGram": 60,
            "injuries": None,
            "medications": None,
        }
        profile = BiometricProfile.model_validate(payload)
        assert profile.gender == Gender.Male
        assert profile.date_of_birth == date(1995, 6, 15)
        assert profile.base_tdee == 2200
        assert profile.fitness_goal == FitnessGoal.LoseFat

    def test_rejects_hallucinated_field(self) -> None:
        payload = {
            **_auditable_base(),
            "userId": str(_uuid()),
            "gender": 0,
            "dateOfBirth": "1995-06-15",
            "heightCm": 175,
            "currentWeightKg": 72,
            "targetWeightKg": 68,
            "currentBodyFatPercentage": None,
            "goalBodyFatPercentage": None,
            "muscleMassKg": None,
            "fitnessGoal": 0,
            "activityLevel": 2,
            "fitnessExperienceLevel": 1,
            "workoutLocationPreference": 1,
            "baseTDEE": 2200,
            "bmr": 1700,
            "dailyProteinTargetGram": None,
            "dailyCarbTargetGram": None,
            "dailyFatTargetGram": None,
            "injuries": None,
            "medications": None,
            "fakeField": True,
        }
        with pytest.raises(ValueError):
            BiometricProfile.model_validate(payload)


class TestAIContextProfile:
    def test_all_scores_required(self) -> None:
        payload = {
            **_auditable_base(),
            "userId": str(_uuid()),
            "adherenceScore": "0.8",
            "burnoutRiskScore": "0.2",
            "churnRiskScore": "0.1",
            "motivationScore": "0.7",
            "recoveryScore": "0.6",
            "stressScore": "0.3",
            "sleepQualityScore": "0.75",
            "nutritionComplianceScore": "0.9",
            "workoutComplianceScore": "0.85",
            "peakEnergyTimeWindow": "06:00-10:00",
            "preferredInterventionStyle": "gentle",
            "lastBurnoutDetectedAt": None,
            "lastWorkoutSkippedAt": None,
            "lastCheatMealAt": None,
            "currentMood": "motivated",
            "aiConfidenceScore": "0.95",
            "lastReplanAt": None,
        }
        ctx = AIContextProfile.model_validate(payload)
        assert ctx.current_mood == "motivated"
        assert ctx.burnout_risk_score == Decimal("0.2")


class TestPersonalizedRoadmap:
    def test_policy_flags(self) -> None:
        payload = {
            **_mongo_base(),
            "userId": str(_uuid()),
            "roadmapName": "Cut Phase",
            "fitnessGoal": "LoseFat",
            "currentPhase": "Week 3",
            "startDate": "2026-01-01T00:00:00+00:00",
            "expectedEndDate": None,
            "currentWeightKg": 72,
            "targetWeightKg": 68,
            "initialFatPercentage": 22,
            "targetFatPercentage": 15,
            "adaptiveAiEnabled": True,
            "allowAiReschedule": True,
            "allowAiIntensityAdjustment": True,
            "allowAiRecoveryDeload": False,
            "roadmapStatus": "Active",
        }
        roadmap = PersonalizedRoadmap.model_validate(payload)
        assert roadmap.allow_ai_reschedule is True
        assert roadmap.roadmap_status == RoadmapStatus.Active


class TestRecoveryProfile:
    def test_fatigue_scores(self) -> None:
        payload = {
            **_mongo_base(),
            "userId": str(_uuid()),
            "currentRecoveryScore": 65,
            "fatigueLevel": 4,
            "sleepRecoveryScore": 70,
            "muscleSorenessScore": 6,
            "cnsFatigueScore": 5,
            "recommendedTrainingIntensity": "light",
            "recommendedWorkoutDuration": 45,
        }
        recovery = RecoveryProfile.model_validate(payload)
        assert recovery.cns_fatigue_score == 5
        assert recovery.muscle_soreness_score == 6


class TestJitContext:
    def test_partial_fetch_allowed(self) -> None:
        ctx = JitContext(biometric_profile=None, user_preference=None)
        assert ctx.is_empty

    def test_rejects_extra_top_level_field(self) -> None:
        with pytest.raises(ValueError):
            JitContext.model_validate({"unknownJitField": True})


class TestLLMOutput:
    def test_dual_output_contract(self) -> None:
        out = LLMAgentOutput.model_validate(
            {
                "spokenResponse": "Nay nghỉ nhé.",
                "toolCalls": [{"action": "RescheduleWorkout", "payload": {"date": "2026-05-25"}}],
            }
        )
        assert out.spoken_response.startswith("Nay")
        assert out.tool_calls[0].action == "RescheduleWorkout"
