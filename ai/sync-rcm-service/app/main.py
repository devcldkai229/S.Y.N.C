"""sync-rcm-service — FastAPI entrypoint.

One-click AI workout generation: collects the user's context (biometrics,
recovery, recent training), filters + ranks the exercise catalog via OpenAI
embeddings, and asks gpt-4o-mini to assemble a session.
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.config import settings
from app.core.envelope import ok
from app.intelligence.llm_generator import llm_enabled

logger = logging.getLogger("sync-rcm")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(
        "sync-rcm-service ready. LLM enabled=%s embedding=%s dim=%s",
        llm_enabled(),
        settings.openai_embedding_model,
        settings.embedding_dim,
    )
    yield


app = FastAPI(title="SYNC RCM", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/health", tags=["Health"])
async def health():
    return ok(
        {
            "status": "healthy",
            "llmEnabled": llm_enabled(),
            "embeddingModel": settings.openai_embedding_model,
            "embeddingDim": settings.embedding_dim,
            "chatModel": settings.openai_model,
        }
    )
