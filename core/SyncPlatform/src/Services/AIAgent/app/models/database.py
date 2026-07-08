"""SQLAlchemy async engine + ORM models for the AIAgent service.

Tables:
- exercise_embeddings : pre-embedded exercise catalog (pgvector)
- ai_usage_logs       : per-user request tracking for rate limiting
"""
import uuid
from datetime import datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import Boolean, DateTime, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

from app.config import settings

engine = create_async_engine(settings.database_url, pool_pre_ping=True, future=True)
SessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


class ExerciseEmbedding(Base):
    __tablename__ = "exercise_embeddings"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    exercise_id: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    exercise_code: Mapped[str] = mapped_column(String(32), nullable=False)
    name_en: Mapped[str] = mapped_column(String(256), nullable=False)
    name_vi: Mapped[str] = mapped_column(String(256), nullable=False, default="")
    content_text: Mapped[str] = mapped_column(Text, nullable=False)
    embedding: Mapped[list[float]] = mapped_column(Vector(settings.embedding_dim), nullable=False)
    category: Mapped[str | None] = mapped_column(String(64))
    difficulty: Mapped[str | None] = mapped_column(String(32))
    body_region: Mapped[str | None] = mapped_column(String(64))
    movement_pattern: Mapped[str | None] = mapped_column(String(64))
    is_compound: Mapped[bool] = mapped_column(Boolean, default=False)
    equipment: Mapped[list] = mapped_column(JSONB, default=list)
    primary_muscles: Mapped[list] = mapped_column(JSONB, default=list)
    recommended_goals: Mapped[list] = mapped_column(JSONB, default=list)
    thumbnail_url: Mapped[str | None] = mapped_column(String(512))
    estimated_calories_per_minute: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class AiUsageLog(Base):
    __tablename__ = "ai_usage_logs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[str] = mapped_column(String(64), nullable=False)
    request_type: Mapped[str] = mapped_column(String(64), nullable=False)
    tokens_used: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


async def get_db():
    async with SessionLocal() as session:
        yield session
