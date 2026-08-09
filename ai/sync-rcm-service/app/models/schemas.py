"""Pydantic request/response DTOs.

Field names are camelCase to match the Flutter client and the rest of the
platform's JSON contract.
"""
from pydantic import BaseModel, Field


class GenerateSessionRequest(BaseModel):
    goal: str = Field(default="", description="Vietnamese goal label, e.g. 'Tăng cơ'")
    sessionTitle: str = Field(default="", description="Name of the session being designed")
    targetMuscleGroup: str | None = None
    desiredExerciseCount: int = Field(default=6, ge=3, le=10)
    excludeExerciseCodes: list[str] = Field(default_factory=list)


class SwapExerciseRequest(BaseModel):
    currentExerciseCode: str
    sessionTitle: str | None = None
    goal: str | None = None
    excludeExerciseCodes: list[str] = Field(default_factory=list)


class GeneratedExercise(BaseModel):
    # `id` mirrors the Exercise catalog DTO shape so the Flutter
    # ExerciseCatalogItem.fromJson (which reads `id`) resolves a valid GUID.
    id: str
    exerciseId: str
    exerciseCode: str
    nameEn: str
    nameVi: str = ""
    category: str = ""
    difficulty: str = ""
    bodyRegion: str = ""
    primaryMuscles: list[str] = Field(default_factory=list)
    equipmentRequired: list[str] = Field(default_factory=list)
    thumbnailUrl: str | None = None
    sets: int = 3
    reps: int = 10
    restSeconds: int = 60
    notes: str = ""


class GenerateSessionResponse(BaseModel):
    exercises: list[GeneratedExercise]
    coachingMessage: str = ""
    rationale: str = ""


class SwapExerciseResponse(BaseModel):
    exercise: GeneratedExercise
    rationale: str = ""
