from fastapi import APIRouter

from sync_agent.api.dependencies import get_app_settings
from sync_agent.api.routes.voice import get_ws_manager

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> dict:
    settings = get_app_settings()
    return {
        "status": "ok",
        "service": settings.app_name,
        "version": "0.1.0",
    }


@router.get("/health/voice")
async def voice_health() -> dict:
    return {
        "status": "ok",
        "active_voice_connections": get_ws_manager().active_count,
    }
