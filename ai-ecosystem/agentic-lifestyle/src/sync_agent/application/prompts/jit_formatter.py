"""Serialize JIT context for LLM system prompts (facts only, no invented fields)."""

import json

from sync_agent.domain.schemas.agent.jit_context import JitContext


def format_jit_context_for_prompt(ctx: JitContext | None) -> str:
    if ctx is None or ctx.is_empty:
        return "Không có dữ liệu JIT từ backend — trả lời thận trọng, không bịa số liệu cá nhân."

    sections: list[str] = []

    if ctx.biometric_profile is not None:
        bio = ctx.biometric_profile
        sections.append(
            "BIOMETRIC_PROFILE:\n"
            + json.dumps(
                {
                    "baseTDEE": bio.base_tdee,
                    "targetWeightKg": float(bio.target_weight_kg),
                    "currentWeightKg": float(bio.current_weight_kg),
                    "dailyProteinTargetGram": bio.daily_protein_target_gram,
                    "dailyCarbTargetGram": bio.daily_carb_target_gram,
                    "dailyFatTargetGram": bio.daily_fat_target_gram,
                    "fitnessGoal": bio.fitness_goal.name,
                },
                ensure_ascii=False,
            )
        )

    if ctx.user_preference is not None:
        pref = ctx.user_preference
        allergies = [
            {"allergenName": a.allergen_name, "severity": a.severity, "notes": a.notes}
            for a in (pref.allergies or [])
        ]
        sections.append(
            "USER_PREFERENCE:\n"
            + json.dumps(
                {
                    "allergies": allergies,
                    "dislikedFoods": pref.disliked_foods or [],
                    "favoriteFoods": pref.favorite_foods or [],
                    "agentPersona": pref.agent_persona.name,
                },
                ensure_ascii=False,
            )
        )

    if ctx.personalized_roadmap is not None:
        rm = ctx.personalized_roadmap
        sections.append(
            "PERSONALIZED_ROADMAP:\n"
            + json.dumps(
                {
                    "roadmapStatus": rm.roadmap_status.name,
                    "adaptiveAiEnabled": rm.adaptive_ai_enabled,
                    "allowAiReschedule": rm.allow_ai_reschedule,
                    "allowAiIntensityAdjustment": rm.allow_ai_intensity_adjustment,
                    "currentPhase": rm.current_phase,
                },
                ensure_ascii=False,
            )
        )

    if ctx.recovery_profile is not None:
        rec = ctx.recovery_profile
        sections.append(
            "RECOVERY_PROFILE:\n"
            + json.dumps(
                {
                    "cnsFatigueScore": rec.cns_fatigue_score,
                    "muscleSorenessScore": rec.muscle_soreness_score,
                    "currentRecoveryScore": rec.current_recovery_score,
                    "recommendedTrainingIntensity": rec.recommended_training_intensity,
                },
                ensure_ascii=False,
            )
        )

    if ctx.ai_context_profile is not None:
        ai = ctx.ai_context_profile
        sections.append(
            "AI_CONTEXT_PROFILE:\n"
            + json.dumps(
                {
                    "burnoutRiskScore": float(ai.burnout_risk_score),
                    "currentMood": ai.current_mood,
                    "recoveryScore": float(ai.recovery_score),
                    "stressScore": float(ai.stress_score),
                },
                ensure_ascii=False,
            )
        )

    return "\n\n".join(sections)
