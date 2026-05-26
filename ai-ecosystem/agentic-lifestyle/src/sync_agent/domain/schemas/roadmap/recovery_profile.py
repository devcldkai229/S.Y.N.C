"""
Roadmap.Domain.Models.RecoveryProfile — JIT context for Workout Action node.
Not in Task 1 list but required by .cursorrules (CnsFatigueScore, MuscleSorenessScore).
"""

from uuid import UUID

from sync_agent.domain.schemas.common import MongoEntityFields


class RecoveryProfile(MongoEntityFields):
    """Maps C# RecoveryProfile exactly."""

    user_id: UUID
    current_recovery_score: int
    fatigue_level: int
    sleep_recovery_score: int
    muscle_soreness_score: int
    cns_fatigue_score: int
    recommended_training_intensity: str
    recommended_workout_duration: int
