"""Admin endpoints — (re)index the exercise catalog into pgvector + stats."""
from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.auth import CurrentUser, get_raw_token, require_admin
from app.core.envelope import ApiResponse, ok
from app.intelligence.indexer import run_indexing
from app.models.database import ExerciseEmbedding, get_db

router = APIRouter(prefix="/api/v1/ai/admin", tags=["AI Admin"])


@router.post("/reindex", response_model=ApiResponse)
async def reindex(
    _: CurrentUser = Depends(require_admin),
    token: str = Depends(get_raw_token),
    db: AsyncSession = Depends(get_db),
) -> ApiResponse:
    count = await run_indexing(token, db)
    return ok({"indexedCount": count, "model": settings.embedding_model}, "Reindex hoàn tất")


@router.get("/stats", response_model=ApiResponse)
async def stats(
    _: CurrentUser = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> ApiResponse:
    total = await db.scalar(select(func.count(ExerciseEmbedding.id)))
    return ok({"totalEmbedded": total or 0})
