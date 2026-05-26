import asyncio
import json
from typing import Any

import structlog
from fastapi import WebSocket, WebSocketDisconnect
from pydantic import ValidationError

from sync_agent.application.voice_pipeline import VoicePipeline
from sync_agent.core.config import Settings
from sync_agent.core.exceptions import AudioBufferError, VoiceSessionError
from sync_agent.domain.voice.protocol import (
    ClientMessageType,
    ServerEnvelope,
    ServerMessageType,
    SessionBindPayload,
)
from sync_agent.domain.voice.session import VoiceSession, VoiceSessionState
from sync_agent.api.websocket.connection_manager import VoiceConnectionManager

logger = structlog.get_logger(__name__)


class VoiceWebSocketHandler:
    def __init__(
        self,
        *,
        manager: VoiceConnectionManager,
        pipeline: VoicePipeline,
        settings: Settings,
    ) -> None:
        self._manager = manager
        self._pipeline = pipeline
        self._settings = settings

    async def handle(self, websocket: WebSocket) -> None:
        await websocket.accept()
        session = VoiceSession()
        await self._manager.register(session, websocket)

        async def send_json(data: dict[str, Any]) -> None:
            await websocket.send_json(data)

        async def send_bytes(data: bytes) -> None:
            await websocket.send_bytes(data)

        try:
            while True:
                message = await websocket.receive()

                if message.get("type") == "websocket.disconnect":
                    break

                if bytes_data := message.get("bytes"):
                    await self._on_audio_bytes(session, bytes_data, send_json=send_json)
                    continue

                if text_data := message.get("text"):
                    await self._on_control_json(
                        session,
                        text_data,
                        send_json=send_json,
                        send_bytes=send_bytes,
                    )
                    continue

        except WebSocketDisconnect:
            logger.info("ws.client_disconnect", connection_id=session.connection_id)
        except Exception:
            logger.exception("ws.unhandled_error", connection_id=session.connection_id)
            await self._safe_error(
                send_json,
                session,
                code="internal_error",
                message="Unexpected server error",
            )
        finally:
            await self._manager.unregister(session.connection_id)

    async def _on_audio_bytes(
        self,
        session: VoiceSession,
        chunk: bytes,
        *,
        send_json: Any,
    ) -> None:
        if session.state == VoiceSessionState.CLOSED:
            return
        if session.state == VoiceSessionState.CONNECTED:
            await self._safe_error(
                send_json,
                session,
                code="not_bound",
                message="Send session.bind before streaming audio",
            )
            return
        if session.state == VoiceSessionState.PROCESSING:
            return

        try:
            async with session.lock:
                session.mark_recording()
                session.ensure_buffer().append(chunk)
        except AudioBufferError as exc:
            await self._safe_error(send_json, session, code="buffer_overflow", message=str(exc))

    async def _on_control_json(
        self,
        session: VoiceSession,
        raw: str,
        *,
        send_json: Any,
        send_bytes: Any,
    ) -> None:
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError:
            await self._safe_error(send_json, session, code="invalid_json", message="Invalid JSON")
            return

        msg_type = payload.get("type")
        if msg_type == ClientMessageType.SESSION_BIND:
            await self._handle_bind(session, payload, send_json=send_json)
        elif msg_type == ClientMessageType.AUDIO_FLUSH:
            await self._handle_flush(session, send_json=send_json, send_bytes=send_bytes)
        elif msg_type == ClientMessageType.AUDIO_CLEAR:
            await self._handle_clear(session)
        elif msg_type == ClientMessageType.PING:
            await send_json(
                ServerEnvelope(
                    type=ServerMessageType.PONG,
                    session_id=session.session_id,
                ).to_json()
            )
        elif msg_type == ClientMessageType.CANCEL:
            await self._handle_cancel(session)
        else:
            await self._safe_error(
                send_json,
                session,
                code="unknown_type",
                message=f"Unknown message type: {msg_type}",
            )

    async def _handle_bind(
        self,
        session: VoiceSession,
        payload: dict[str, Any],
        *,
        send_json: Any,
    ) -> None:
        try:
            bind = SessionBindPayload.model_validate(payload)
        except ValidationError as exc:
            await self._safe_error(send_json, session, code="validation_error", message=str(exc))
            return

        session.bind(
            user_id=bind.user_id,
            session_id=bind.session_id,
            audio_format=bind.audio_format,
            max_buffer_bytes=self._settings.audio_max_buffer_bytes,
            sample_width_bytes=self._settings.audio_sample_width_bytes,
            bearer_token=bind.access_token,
        )

        structlog.contextvars.bind_contextvars(
            user_id=bind.user_id,
            session_id=bind.session_id,
            connection_id=session.connection_id,
        )

        await send_json(
            ServerEnvelope(
                type=ServerMessageType.SESSION_READY,
                session_id=bind.session_id,
                payload={
                    "connection_id": session.connection_id,
                    "audio_format": bind.audio_format.model_dump(),
                },
            ).to_json()
        )

    async def _handle_clear(self, session: VoiceSession) -> None:
        if session.buffer:
            async with session.lock:
                session.buffer.clear()

    async def _handle_cancel(self, session: VoiceSession) -> None:
        if session.pipeline_task and not session.pipeline_task.done():
            session.pipeline_task.cancel()
        session.mark_idle()

    async def _handle_flush(
        self,
        session: VoiceSession,
        *,
        send_json: Any,
        send_bytes: Any,
    ) -> None:
        if session.state == VoiceSessionState.CONNECTED:
            raise VoiceSessionError("Session not bound")
        if session.state == VoiceSessionState.PROCESSING:
            return

        session.mark_processing()

        async def run_pipeline() -> None:
            try:
                await asyncio.wait_for(
                    self._pipeline.process_utterance(
                        session,
                        send_json=send_json,
                        send_bytes=send_bytes,
                    ),
                    timeout=self._settings.ws_pipeline_timeout_sec,
                )
            except asyncio.CancelledError:
                logger.info("pipeline.cancelled", session_id=session.session_id)
                session.mark_idle()
            except TimeoutError:
                await self._safe_error(
                    send_json,
                    session,
                    code="pipeline_timeout",
                    message="Processing timed out",
                )
                session.mark_idle()

        session.pipeline_task = asyncio.create_task(run_pipeline())

    async def _safe_error(
        self,
        send_json: Any,
        session: VoiceSession,
        *,
        code: str,
        message: str,
    ) -> None:
        await send_json(
            ServerEnvelope(
                type=ServerMessageType.ERROR,
                session_id=session.session_id,
                payload={"code": code, "message": message},
            ).to_json()
        )
