"""Minimal RAG result — only fields needed for LLM context window."""

from sync_agent.domain.schemas.common import StrictModel


class ExerciseRagHit(StrictModel):
    """Subset of exercise_catalog for Workout RAG node."""

    exercise_code: str
    name_vi: str | None = None
    ai_coaching_cues: list[str]
    common_mistakes: list[str]
    distance: float | None = None


class ExerciseRagSearchResult(StrictModel):
    query: str
    hits: list[ExerciseRagHit]

    def to_prompt_context(self) -> str:
        """Compact text block for LLM system/context injection."""
        if not self.hits:
            return "Không tìm thấy bài tập liên quan trong catalog SYNC."
        parts: list[str] = []
        for index, hit in enumerate(self.hits, start=1):
            cues = "; ".join(hit.ai_coaching_cues) if hit.ai_coaching_cues else "—"
            mistakes = "; ".join(hit.common_mistakes) if hit.common_mistakes else "—"
            label = hit.name_vi or hit.exercise_code
            parts.append(
                f"[{index}] {label} ({hit.exercise_code})\n"
                f"  Coaching: {cues}\n"
                f"  Common mistakes: {mistakes}"
            )
        return "\n\n".join(parts)
