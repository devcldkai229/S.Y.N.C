"""Local reindex helper: embed the exercise catalog into pgvector.

Mints a short-lived SystemAdmin JWT (shared HS256 secret/issuer/audience) and
runs the same pipeline as POST /api/v1/ai/admin/reindex — without needing a real
admin login. Requires the Exercise service (EXERCISE_SERVICE_URL) to be running
and OPENAI_API_KEY to be set.

Run once after seeding the exercise catalog (and after init_db):
    python -m scripts.reindex_local
"""
import asyncio
from datetime import datetime, timedelta, timezone

import jwt

from app.config import settings
from app.intelligence.indexer import run_indexing
from app.models.database import SessionLocal

ROLE_CLAIM = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
NAMEID_CLAIM = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"


def _mint_token() -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": "local-reindex",
        NAMEID_CLAIM: "local-reindex",
        ROLE_CLAIM: "SystemAdmin",
        "iss": settings.jwt_issuer,
        "aud": settings.jwt_audience,
        "iat": now,
        "exp": now + timedelta(minutes=10),
    }
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


async def main() -> None:
    token = _mint_token()
    async with SessionLocal() as db:
        count = await run_indexing(token, db)
    if count == 0:
        print(
            "reindexed 0 exercises — is the Exercise service running at "
            f"{settings.exercise_service_url}? Is its catalog seeded?"
        )
    else:
        print(f"reindexed {count} exercises into exercise_embeddings")


if __name__ == "__main__":
    asyncio.run(main())
