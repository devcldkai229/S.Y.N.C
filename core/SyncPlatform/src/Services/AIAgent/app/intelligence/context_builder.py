"""Step 1 — collect + summarise the user's context from IAM + Roadmap services."""
import asyncio
from dataclasses import dataclass, field

from app.services.iam_client import fetch_iam_bundle
from app.services.roadmap_client import fetch_roadmap_bundle


@dataclass
class UserContext:
    gender: str = ""
    age: int | None = None
    fitness_goal: str = ""
    experience_level: str = "Beginner"
    workout_location: str = ""
    equipment: list[str] = field(default_factory=list)
    injuries: list[str] = field(default_factory=list)
    recovery_score: int | None = None
    recommended_intensity: str = ""
    recently_trained: list[str] = field(default_factory=list)
    agent_persona: str = "FriendlyBuddy"
    motivation_style: str = "Supportive"


def _experience_from(bio: dict | None, fitness: dict | None) -> str:
    for src in (bio, fitness):
        if src and src.get("fitnessExperienceLevel"):
            return str(src["fitnessExperienceLevel"])
    return "Beginner"


def _build(bio, prefs, recovery, recent) -> UserContext:
    fitness = (prefs or {}).get("fitness") if isinstance(prefs, dict) else None
    preferences = (prefs or {}).get("preferences") if isinstance(prefs, dict) else None
    primary = bio or fitness or {}

    recently: list[str] = []
    for ex in recent or []:
        for block in ex.get("exercises", []) if isinstance(ex, dict) else []:
            name = block.get("exerciseName")
            if name:
                recently.append(str(name))

    return UserContext(
        gender=str(primary.get("gender", "")),
        fitness_goal=str(primary.get("fitnessGoal", "")),
        experience_level=_experience_from(bio, fitness),
        workout_location=str(primary.get("workoutLocationPreference", "")),
        equipment=[],
        injuries=[str(i) for i in (primary.get("injuries") or [])],
        recovery_score=(recovery or {}).get("currentRecoveryScore"),
        recommended_intensity=str((recovery or {}).get("recommendedTrainingIntensity", "")),
        recently_trained=recently[:10],
        agent_persona=str((preferences or {}).get("agentPersona", "FriendlyBuddy")),
        motivation_style=str((preferences or {}).get("motivationStyle", "Supportive")),
    )


async def build_user_context(token: str) -> UserContext:
    (bio, prefs), (recovery, recent) = await asyncio.gather(
        fetch_iam_bundle(token),
        fetch_roadmap_bundle(token),
    )
    return _build(bio, prefs, recovery, recent)
