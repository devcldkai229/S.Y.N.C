"""Router intents — maps to LangGraph worker nodes in .cursorrules."""

from enum import StrEnum


class AgentIntent(StrEnum):
    """Which worker node should handle the current turn."""

    NUTRITION = "nutrition"
    WORKOUT_RAG = "workout_rag"
    WORKOUT_ACTION = "workout_action"
    UNKNOWN = "unknown"
