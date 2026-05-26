"""Iam.Domain.Enums — numeric values match C# exactly."""

from enum import IntEnum


class Gender(IntEnum):
    Male = 0
    Female = 1
    Other = 2
    PreferNotToSay = 3


class FitnessGoal(IntEnum):
    LoseFat = 0
    BuildMuscle = 1
    Maintain = 2
    Recomposition = 3
    ImproveEndurance = 4
    GeneralHealth = 5


class ActivityLevel(IntEnum):
    Sedentary = 0
    LightlyActive = 1
    ModeratelyActive = 2
    VeryActive = 3
    Athlete = 4


class FitnessExperienceLevel(IntEnum):
    Beginner = 0
    Intermediate = 1
    Advanced = 2


class WorkoutLocationPreference(IntEnum):
    Home = 0
    Gym = 1
    Outdoor = 2
    Hybrid = 3


class AgentPersona(IntEnum):
    StrictCoach = 0
    FriendlyBuddy = 1
    CalmMentor = 2
    EnergeticTrainer = 3


class MotivationStyle(IntEnum):
    Supportive = 0
    Aggressive = 1
    DisciplineFocused = 2
    Friendly = 3
    Competitive = 4
    Minimal = 5
