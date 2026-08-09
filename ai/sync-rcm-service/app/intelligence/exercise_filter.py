"""Step 2 — constraints that decide which exercises a user should NOT be given."""
from app.intelligence.context_builder import UserContext

_DIFFICULTY_BY_LEVEL = {
    "Beginner": ["Beginner"],
    "Intermediate": ["Beginner", "Intermediate"],
    "Advanced": ["Beginner", "Intermediate", "Advanced"],
}

# crude injury keyword -> body region mapping (body regions: UpperBody/LowerBody/Core/FullBody)
_INJURY_REGION = {
    "back": "Core",
    "lưng": "Core",
    "knee": "LowerBody",
    "gối": "LowerBody",
    "ankle": "LowerBody",
    "hip": "LowerBody",
    "shoulder": "UpperBody",
    "vai": "UpperBody",
    "elbow": "UpperBody",
    "wrist": "UpperBody",
    "cổ tay": "UpperBody",
}


def allowed_difficulties(level: str) -> list[str]:
    return _DIFFICULTY_BY_LEVEL.get(level, ["Beginner", "Intermediate"])


def injured_regions(ctx: UserContext) -> list[str]:
    regions: set[str] = set()
    for injury in ctx.injuries:
        low = injury.lower()
        for keyword, region in _INJURY_REGION.items():
            if keyword in low:
                regions.add(region)
    return list(regions)
