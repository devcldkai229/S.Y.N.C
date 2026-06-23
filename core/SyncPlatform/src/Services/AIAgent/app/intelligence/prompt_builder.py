"""Step 4a — build DeepSeek prompts for assembling / swapping exercises."""
from app.intelligence.context_builder import UserContext
from app.models.database import ExerciseEmbedding


def _exercise_line(ex: ExerciseEmbedding) -> str:
    muscles = ", ".join(ex.primary_muscles or []) or "n/a"
    equip = ", ".join(ex.equipment or []) or "Bodyweight"
    return (
        f"- {ex.exercise_code} | {ex.name_en} ({ex.name_vi}) | "
        f"{ex.difficulty} | {ex.body_region} | muscles: {muscles} | equipment: {equip}"
    )


def _user_block(ctx: UserContext) -> str:
    return (
        f"Goal: {ctx.fitness_goal or 'general fitness'} | "
        f"Level: {ctx.experience_level} | Location: {ctx.workout_location or 'gym'}\n"
        f"Injuries: {', '.join(ctx.injuries) or 'none'} | "
        f"Recovery: {ctx.recovery_score if ctx.recovery_score is not None else 'unknown'}/100 | "
        f"Recently trained: {', '.join(ctx.recently_trained[:5]) or 'none'}"
    )


def build_session_prompt(
    ctx: UserContext,
    candidates: list[ExerciseEmbedding],
    session_title: str,
    count: int,
) -> tuple[str, str]:
    system = (
        "You are SYNC AI Coach. Design ONE workout session by selecting exercises "
        "from the provided list ONLY. Return valid JSON only.\n"
        "Rules:\n"
        f"1. Pick {count} exercises ordered warm-up/compound first, isolation later.\n"
        "2. Use ONLY exerciseCode values from the list.\n"
        "3. Assign sets, reps, restSeconds matching the user's goal and level.\n"
        "4. If recovery < 50, reduce volume.\n"
        "5. Avoid muscles trained in the last 24h.\n"
        "6. 'notes' must be a short Vietnamese coaching cue."
    )
    exercise_list = "\n".join(_exercise_line(c) for c in candidates)
    user = (
        f"## Session: {session_title or 'Workout'}\n"
        f"## User\n{_user_block(ctx)}\n\n"
        f"## Available Exercises\n{exercise_list}\n\n"
        'Return JSON: {"exercises":[{"exerciseCode":"...","sets":N,"reps":N,'
        '"restSeconds":N,"notes":"..."}],"coachingMessage":"...","rationale":"..."}'
    )
    return system, user


def build_swap_prompt(
    ctx: UserContext,
    current_code: str,
    candidates: list[ExerciseEmbedding],
    session_title: str | None,
) -> tuple[str, str]:
    system = (
        "You are SYNC AI Coach. Replace ONE exercise with a single alternative "
        "chosen from the provided list ONLY. Return valid JSON only.\n"
        "Pick the best alternative targeting the same muscle group, suitable for the "
        "user. Assign sets/reps/restSeconds and a short Vietnamese note."
    )
    exercise_list = "\n".join(_exercise_line(c) for c in candidates)
    user = (
        f"## Session: {session_title or 'Workout'}\n"
        f"## User\n{_user_block(ctx)}\n\n"
        f"## Replacing exercise code: {current_code}\n"
        f"## Candidate replacements\n{exercise_list}\n\n"
        'Return JSON: {"exerciseCode":"...","sets":N,"reps":N,"restSeconds":N,'
        '"notes":"...","rationale":"..."}'
    )
    return system, user
