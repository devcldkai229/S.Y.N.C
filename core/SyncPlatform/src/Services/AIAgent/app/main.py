"""SYNC AIAgent — FastAPI entrypoint.

One-click AI workout generation: collects the user's context (biometrics,
recovery, recent training), filters + ranks the exercise catalog locally, and
asks DeepSeek to assemble a session.
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.envelope import ok
from app.intelligence.embedding_ranker import load_model
from app.intelligence.llm_generator import llm_enabled

logger = logging.getLogger("aiagent")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Loading embedding model on startup ...")
    load_model()
    logger.info("Embedding model ready. LLM enabled=%s", llm_enabled())
    yield


app = FastAPI(title="SYNC AIAgent", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/health", tags=["Health"])
async def health():
    return ok({"status": "healthy", "llmEnabled": llm_enabled()})
