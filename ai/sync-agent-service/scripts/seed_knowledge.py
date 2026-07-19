"""Seed corpus kiến thức (app/knowledge/*.md) vào pgvector (bảng ai_knowledge).

Chạy 1 lần sau khi migration đã tạo bảng:
    python -m scripts.seed_knowledge
Yêu cầu: OPENAI_API_KEY + Postgres(pgvector) đang chạy.
"""
from __future__ import annotations

import asyncio
import pathlib

import asyncpg

from app.config import get_settings
from app.models.embeddings import embed_text

_KNOWLEDGE_DIR = pathlib.Path(__file__).resolve().parents[1] / "app" / "knowledge"


async def main() -> None:
    settings = get_settings()
    pool = await asyncpg.create_pool(settings.postgres_dsn)
    async with pool.acquire() as conn:
        await conn.execute("DELETE FROM ai_knowledge")  # reseed sạch
        for md in _KNOWLEDGE_DIR.glob("*.md"):
            chunks = [c.strip() for c in md.read_text(encoding="utf-8").split("\n---\n")]
            for chunk in chunks:
                if len(chunk) < 40:
                    continue
                emb = await embed_text(chunk)
                vec = "[" + ",".join(str(x) for x in emb) + "]"
                await conn.execute(
                    "INSERT INTO ai_knowledge(source, content, embedding) VALUES($1,$2,$3)",
                    md.name, chunk, vec,
                )
                print(f"seeded chunk from {md.name} ({len(chunk)} chars)")
    await pool.close()
    print("done.")


if __name__ == "__main__":
    asyncio.run(main())
