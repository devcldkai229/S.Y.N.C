"""Lightweight per-user monthly rate limiting via ai_usage_logs."""
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.database import AiUsageLog


async def check_usage_limit(user_id: str, db: AsyncSession) -> None:
    since = datetime.now(timezone.utc) - timedelta(days=30)
    count = await db.scalar(
        select(func.count(AiUsageLog.id)).where(
            AiUsageLog.user_id == user_id, AiUsageLog.created_at >= since
        )
    )
    if (count or 0) >= settings.monthly_ai_request_limit:
        raise HTTPException(status_code=429, detail="Đã đạt giới hạn AI trong tháng này.")


async def log_usage(user_id: str, request_type: str, tokens: int, db: AsyncSession) -> None:
    db.add(AiUsageLog(user_id=user_id, request_type=request_type, tokens_used=tokens))
    await db.commit()
