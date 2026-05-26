from fastapi import APIRouter, Depends, WebSocket

from sync_agent.api.dependencies import get_app_settings, get_voice_pipeline
from sync_agent.api.websocket.connection_manager import VoiceConnectionManager
from sync_agent.api.websocket.voice_handler import VoiceWebSocketHandler
from sync_agent.application.voice_pipeline import VoicePipeline
from sync_agent.core.config import Settings

router = APIRouter(tags=["voice"])

_ws_manager = VoiceConnectionManager()


def get_ws_manager() -> VoiceConnectionManager:
    return _ws_manager


@router.websocket("/ws/voice")
async def voice_websocket(
    websocket: WebSocket,
    pipeline: VoicePipeline = Depends(get_voice_pipeline),
    settings: Settings = Depends(get_app_settings),
) -> None:
    """
    Bi-directional voice channel.

    - JSON text frames: control (`session.bind`, `audio.flush`, …)
    - Binary frames: PCM s16le audio chunks (after bind)
    """
    handler = VoiceWebSocketHandler(
        manager=_ws_manager,
        pipeline=pipeline,
        settings=settings,
    )
    await handler.handle(websocket)
