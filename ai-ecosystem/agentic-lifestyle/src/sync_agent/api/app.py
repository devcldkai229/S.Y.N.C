from contextlib import asynccontextmanager
from collections.abc import AsyncIterator

import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from sync_agent.api.dependencies import get_app_settings, get_stt_service, get_tts_service
from sync_agent.api.routes import health, voice
from sync_agent.core.config import Settings
from sync_agent.core.logging import configure_logging

logger = structlog.get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings: Settings = app.state.settings
    try:
        settings.validate_runtime()
    except ValueError as exc:
        logger.error("startup.config_invalid", error=str(exc))
        raise
    logger.info("startup.complete", host=settings.host, port=settings.port)
    yield
    await get_stt_service().aclose()
    await get_tts_service().aclose()
    logger.info("shutdown.complete")


def create_app() -> FastAPI:
    settings = get_app_settings()
    configure_logging(debug=settings.debug)

    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.debug else None,
        redoc_url=None,
    )
    app.state.settings = settings

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router)
    app.include_router(voice.router)

    return app
