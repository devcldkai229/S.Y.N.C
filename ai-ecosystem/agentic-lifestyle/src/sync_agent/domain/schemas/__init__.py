"""
Pydantic mirrors of C# domain entities (strict, extra=forbid).

Mapped from:
- core/SyncPlatform/src/Services/Iam/Iam.Domain
- core/SyncPlatform/src/Services/Roadmap/Roadmap.Domain
- domain.md
"""

from sync_agent.domain.schemas.agent.intent import AgentIntent
from sync_agent.domain.schemas.agent.jit_context import JitContext
from sync_agent.domain.schemas.agent.llm_output import LLMAgentOutput, ToolCall
from sync_agent.domain.schemas.iam.ai_context_profile import AIContextProfile
from sync_agent.domain.schemas.iam.allergy_item import AllergyItem
from sync_agent.domain.schemas.iam.biometric_profile import BiometricProfile
from sync_agent.domain.schemas.iam.user_preference import UserPreference
from sync_agent.domain.schemas.roadmap.personalized_roadmap import PersonalizedRoadmap
from sync_agent.domain.schemas.roadmap.recovery_profile import RecoveryProfile

__all__ = [
    "AgentIntent",
    "AIContextProfile",
    "AllergyItem",
    "BiometricProfile",
    "JitContext",
    "LLMAgentOutput",
    "PersonalizedRoadmap",
    "RecoveryProfile",
    "ToolCall",
    "UserPreference",
]
