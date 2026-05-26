"""JIT context bundle fetched from C# APIs at turn runtime."""

from sync_agent.domain.schemas.common import StrictModel
from sync_agent.domain.schemas.iam.ai_context_profile import AIContextProfile
from sync_agent.domain.schemas.iam.biometric_profile import BiometricProfile
from sync_agent.domain.schemas.iam.user_preference import UserPreference
from sync_agent.domain.schemas.roadmap.personalized_roadmap import PersonalizedRoadmap
from sync_agent.domain.schemas.roadmap.recovery_profile import RecoveryProfile


class JitContext(StrictModel):
    """
    Aggregated system context for one conversation turn.
    Only contains models populated by HTTP tools — never invent fields.
    """

    biometric_profile: BiometricProfile | None = None
    user_preference: UserPreference | None = None
    personalized_roadmap: PersonalizedRoadmap | None = None
    ai_context_profile: AIContextProfile | None = None
    recovery_profile: RecoveryProfile | None = None

    @property
    def is_empty(self) -> bool:
        return not any(
            (
                self.biometric_profile,
                self.user_preference,
                self.personalized_roadmap,
                self.ai_context_profile,
                self.recovery_profile,
            )
        )
