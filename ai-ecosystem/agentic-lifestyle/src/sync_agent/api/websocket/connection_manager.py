import asyncio
from dataclasses import dataclass, field

import structlog
from fastapi import WebSocket

from sync_agent.domain.voice.session import VoiceSession

logger = structlog.get_logger(__name__)


@dataclass
class VoiceConnectionManager:
    """Tracks active voice WebSocket sessions for observability and cleanup."""

    _sessions: dict[str, VoiceSession] = field(default_factory=dict)
    _lock: asyncio.Lock = field(default_factory=asyncio.Lock)

    async def register(self, session: VoiceSession, websocket: WebSocket) -> None:
        async with self._lock:
            self._sessions[session.connection_id] = session
        logger.info(
            "ws.connected",
            connection_id=session.connection_id,
            active=len(self._sessions),
        )

    async def unregister(self, connection_id: str) -> None:
        async with self._lock:
            session = self._sessions.pop(connection_id, None)
        if session:
            session.close()
        logger.info(
            "ws.disconnected",
            connection_id=connection_id,
            active=len(self._sessions),
        )

    @property
    def active_count(self) -> int:
        return len(self._sessions)
