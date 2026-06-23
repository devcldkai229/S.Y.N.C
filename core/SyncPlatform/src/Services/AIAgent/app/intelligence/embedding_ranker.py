"""Step 3 — local embedding model + pgvector cosine ranking.

The model is loaded once at startup (see app.main lifespan). Ranking applies the
SQL constraints from exercise_filter and orders by cosine distance, excluding any
codes the caller already used/rejected (so generate/swap never repeat).
"""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.intelligence.context_builder import UserContext
from app.intelligence.exercise_filter import allowed_difficulties, injured_regions
from app.models.database import ExerciseEmbedding

_model = None


def load_model():
    """Load the SentenceTransformer once. Called from the FastAPI lifespan."""
    global _model
    if _model is None:
        from sentence_transformers import SentenceTransformer

        _model = SentenceTransformer(settings.embedding_model)
    return _model


def encode(text: str) -> list[float]:
    vec = load_model().encode([text], normalize_embeddings=True)[0]
    return vec.tolist()


def compose_user_need(ctx: UserContext, target_muscle: str | None = None) -> str:
    recent = ", ".join(ctx.recently_trained[:5]) or "none"
    focus = target_muscle or "balanced full programming"
    return (
        f"Goal: {ctx.fitness_goal or 'general fitness'}\n"
        f"Experience: {ctx.experience_level}\n"
        f"Location: {ctx.workout_location or 'gym'}\n"
        f"Focus today: {focus}\n"
        f"Recovery: {ctx.recovery_score if ctx.recovery_score is not None else 'unknown'}/100\n"
        f"Preferred intensity: {ctx.recommended_intensity or 'moderate'}\n"
        f"Recently trained: {recent}"
    )


async def rank_candidates(
    db: AsyncSession,
    ctx: UserContext,
    user_vec: list[float],
    *,
    limit: int,
    excluded: set[str] | None = None,
    body_region: str | None = None,
) -> list[ExerciseEmbedding]:
    excluded = excluded or set()
    stmt = select(ExerciseEmbedding).where(ExerciseEmbedding.is_active.is_(True))
    stmt = stmt.where(ExerciseEmbedding.difficulty.in_(allowed_difficulties(ctx.experience_level)))

    regions = injured_regions(ctx)
    if regions:
        stmt = stmt.where(ExerciseEmbedding.body_region.notin_(regions))
    if body_region:
        stmt = stmt.where(ExerciseEmbedding.body_region == body_region)
    if excluded:
        stmt = stmt.where(ExerciseEmbedding.exercise_code.notin_(excluded))

    stmt = stmt.order_by(ExerciseEmbedding.embedding.cosine_distance(user_vec)).limit(limit)
    result = await db.execute(stmt)
    return list(result.scalars().all())
