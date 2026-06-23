"""Exercise indexing pipeline — fetch catalog → embed locally → upsert pgvector."""
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.intelligence.embedding_ranker import load_model
from app.models.database import ExerciseEmbedding
from app.services.exercise_client import fetch_catalog


def _compose_text(ex: dict) -> str:
    muscles = ", ".join(ex.get("primaryMuscles") or [])
    equip = ", ".join(ex.get("equipmentRequired") or []) or "Bodyweight"
    goals = ", ".join(ex.get("recommendedGoals") or [])
    tags = ", ".join(ex.get("movementTags") or [])
    return (
        f"{ex.get('nameEn', '')} ({ex.get('nameVi', '')})\n"
        f"{ex.get('category', '')} | {ex.get('difficulty', '')} | {ex.get('bodyRegion', '')}\n"
        f"Muscles: {muscles}\nEquipment: {equip}\nGoals: {goals}\nTags: {tags}"
    )


async def run_indexing(token: str, db: AsyncSession) -> int:
    exercises = await fetch_catalog(token)
    if not exercises:
        return 0

    texts = [_compose_text(ex) for ex in exercises]
    vectors = load_model().encode(texts, normalize_embeddings=True, show_progress_bar=False)

    for ex, text, vec in zip(exercises, texts, vectors):
        exercise_id = str(ex.get("id", ""))
        if not exercise_id:
            continue
        existing = await db.scalar(
            select(ExerciseEmbedding).where(ExerciseEmbedding.exercise_id == exercise_id)
        )
        payload = dict(
            exercise_code=str(ex.get("exerciseCode", "")),
            name_en=str(ex.get("nameEn", "")),
            name_vi=str(ex.get("nameVi", "")),
            content_text=text,
            embedding=vec.tolist(),
            category=str(ex.get("category", "")),
            difficulty=str(ex.get("difficulty", "")),
            body_region=str(ex.get("bodyRegion", "")),
            movement_pattern=str(ex.get("movementPattern", "")),
            is_compound=bool(ex.get("isCompound", False)),
            equipment=ex.get("equipmentRequired") or [],
            primary_muscles=ex.get("primaryMuscles") or [],
            recommended_goals=ex.get("recommendedGoals") or [],
            thumbnail_url=ex.get("thumbnailUrl"),
            estimated_calories_per_minute=int(ex.get("estimatedCaloriesPerMinute") or 0),
            is_active=bool(ex.get("isActive", True)),
        )
        if existing:
            for key, value in payload.items():
                setattr(existing, key, value)
        else:
            db.add(ExerciseEmbedding(exercise_id=exercise_id, **payload))

    await db.commit()
    return len(exercises)
