"""Orchestration for the two app-facing operations: generate session exercises
and swap a single exercise. Tiered: SQL filter → embedding rank → DeepSeek LLM,
with a deterministic fallback when the LLM is unavailable.
"""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.intelligence.context_builder import UserContext, build_user_context
from app.intelligence.embedding_ranker import compose_user_need, encode, rank_candidates
from app.intelligence.llm_generator import LlmUnavailable, complete_json
from app.intelligence.prompt_builder import build_session_prompt, build_swap_prompt
from app.models.database import ExerciseEmbedding
from app.models.schemas import (
    GeneratedExercise,
    GenerateSessionResponse,
    SwapExerciseResponse,
)


def _default_volume(ctx: UserContext) -> tuple[int, int, int]:
    goal = (ctx.fitness_goal or "").lower()
    if "strength" in goal or "sức mạnh" in goal:
        return 4, 5, 120
    if "fat" in goal or "mỡ" in goal or "endurance" in goal:
        return 3, 14, 45
    if "muscle" in goal or "cơ" in goal:
        return 4, 10, 75
    return 3, 10, 60


def _to_generated(ex: ExerciseEmbedding, sets: int, reps: int, rest: int, notes: str) -> GeneratedExercise:
    return GeneratedExercise(
        id=ex.exercise_id,
        exerciseId=ex.exercise_id,
        exerciseCode=ex.exercise_code,
        nameEn=ex.name_en,
        nameVi=ex.name_vi or "",
        category=ex.category or "",
        difficulty=ex.difficulty or "",
        bodyRegion=ex.body_region or "",
        primaryMuscles=list(ex.primary_muscles or []),
        equipmentRequired=list(ex.equipment or []),
        thumbnailUrl=ex.thumbnail_url,
        sets=sets,
        reps=reps,
        restSeconds=rest,
        notes=notes,
    )


async def generate_session_exercises(
    token: str,
    db: AsyncSession,
    *,
    goal: str,
    session_title: str,
    target_muscle: str | None,
    count: int,
    excluded: set[str],
) -> tuple[GenerateSessionResponse, int]:
    ctx = await build_user_context(token)
    if goal:
        ctx.fitness_goal = goal  # honour the goal chosen in the create flow

    user_vec = encode(compose_user_need(ctx, target_muscle))
    candidates = await rank_candidates(
        db, ctx, user_vec, limit=max(count * 2, 12), excluded=excluded
    )
    if not candidates:
        return GenerateSessionResponse(exercises=[], coachingMessage="", rationale=""), 0

    by_code = {c.exercise_code: c for c in candidates}
    s, r, rest = _default_volume(ctx)
    tokens = 0

    try:
        system, user = build_session_prompt(ctx, candidates, session_title, count)
        parsed = await complete_json(system, user)
        tokens = int(parsed.pop("_tokens", 0))
        picked: list[GeneratedExercise] = []
        for item in parsed.get("exercises", []):
            ex = by_code.get(item.get("exerciseCode"))
            if not ex:
                continue
            picked.append(
                _to_generated(
                    ex,
                    int(item.get("sets", s)),
                    int(item.get("reps", r)),
                    int(item.get("restSeconds", rest)),
                    str(item.get("notes", "")),
                )
            )
        if picked:
            return (
                GenerateSessionResponse(
                    exercises=picked[:count],
                    coachingMessage=str(parsed.get("coachingMessage", "")),
                    rationale=str(parsed.get("rationale", "")),
                ),
                tokens,
            )
    except LlmUnavailable:
        pass

    # Deterministic fallback: top-ranked candidates with default volume.
    fallback = [_to_generated(c, s, r, rest, "") for c in candidates[:count]]
    return (
        GenerateSessionResponse(
            exercises=fallback,
            coachingMessage="Gợi ý bài tập dựa trên hồ sơ của bạn.",
            rationale="Chọn theo mục tiêu, kinh nghiệm và mức hồi phục.",
        ),
        tokens,
    )


async def swap_exercise(
    token: str,
    db: AsyncSession,
    *,
    current_code: str,
    goal: str | None,
    session_title: str | None,
    excluded: set[str],
) -> tuple[SwapExerciseResponse | None, int]:
    ctx = await build_user_context(token)
    if goal:
        ctx.fitness_goal = goal

    current = await db.scalar(
        select(ExerciseEmbedding).where(ExerciseEmbedding.exercise_code == current_code)
    )
    target_region = current.body_region if current else None
    focus = ", ".join(current.primary_muscles or []) if current else None

    exclude_all = set(excluded) | {current_code}
    user_vec = encode(compose_user_need(ctx, focus or target_region))
    candidates = await rank_candidates(
        db, ctx, user_vec, limit=8, excluded=exclude_all, body_region=target_region
    )
    if not candidates:  # relax region constraint
        candidates = await rank_candidates(
            db, ctx, user_vec, limit=8, excluded=exclude_all
        )
    if not candidates:
        return None, 0

    by_code = {c.exercise_code: c for c in candidates}
    s, r, rest = _default_volume(ctx)
    tokens = 0

    try:
        system, user = build_swap_prompt(ctx, current_code, candidates, session_title)
        parsed = await complete_json(system, user, max_tokens=300)
        tokens = int(parsed.pop("_tokens", 0))
        ex = by_code.get(parsed.get("exerciseCode")) or candidates[0]
        return (
            SwapExerciseResponse(
                exercise=_to_generated(
                    ex,
                    int(parsed.get("sets", s)),
                    int(parsed.get("reps", r)),
                    int(parsed.get("restSeconds", rest)),
                    str(parsed.get("notes", "")),
                ),
                rationale=str(parsed.get("rationale", "")),
            ),
            tokens,
        )
    except LlmUnavailable:
        pass

    return (
        SwapExerciseResponse(
            exercise=_to_generated(candidates[0], s, r, rest, ""),
            rationale="Bài thay thế cùng nhóm cơ, phù hợp hồ sơ của bạn.",
        ),
        tokens,
    )
