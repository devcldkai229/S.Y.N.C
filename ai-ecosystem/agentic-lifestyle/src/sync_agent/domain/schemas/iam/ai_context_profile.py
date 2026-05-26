"""Iam.Domain.Models.AIContextProfile + BaseAuditableEntity."""

from datetime import datetime
from uuid import UUID

from sync_agent.domain.schemas.common import AuditableEntityFields, DecimalField


class AIContextProfile(AuditableEntityFields):
    """Maps C# AIContextProfile (excludes navigation property User)."""

    user_id: UUID
    adherence_score: DecimalField
    burnout_risk_score: DecimalField
    churn_risk_score: DecimalField
    motivation_score: DecimalField
    recovery_score: DecimalField
    stress_score: DecimalField
    sleep_quality_score: DecimalField
    nutrition_compliance_score: DecimalField
    workout_compliance_score: DecimalField
    peak_energy_time_window: str | None = None
    preferred_intervention_style: str | None = None
    last_burnout_detected_at: datetime | None = None
    last_workout_skipped_at: datetime | None = None
    last_cheat_meal_at: datetime | None = None
    current_mood: str | None = None
    ai_confidence_score: DecimalField
    last_replan_at: datetime | None = None
