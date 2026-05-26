"""WebSocket control-plane message types (JSON). Binary frames carry raw audio."""

from enum import StrEnum
from typing import Any, Literal

from pydantic import BaseModel, Field


class ClientMessageType(StrEnum):
    SESSION_BIND = "session.bind"
    AUDIO_FLUSH = "audio.flush"
    AUDIO_CLEAR = "audio.clear"
    PING = "ping"
    CANCEL = "cancel"


class ServerMessageType(StrEnum):
    SESSION_READY = "session.ready"
    PONG = "pong"
    STT_FINAL = "stt.final"
    ASSISTANT_TEXT = "assistant.text"
    TTS_START = "tts.start"
    TTS_END = "tts.end"
    TOOL_PUBLISHED = "tool.published"
    PIPELINE_START = "pipeline.start"
    PIPELINE_END = "pipeline.end"
    ERROR = "error"


class AudioFormat(BaseModel):
    codec: Literal["pcm_s16le"] = "pcm_s16le"
    sample_rate: int = 16_000
    channels: int = 1


class SessionBindPayload(BaseModel):
    type: Literal[ClientMessageType.SESSION_BIND] = ClientMessageType.SESSION_BIND
    user_id: str
    session_id: str
    current_time: str | None = None
    access_token: str | None = Field(
        default=None,
        description="JWT for SYNC C# Gateway (JIT context HTTP)",
    )
    audio_format: AudioFormat = Field(default_factory=AudioFormat)


class AudioFlushPayload(BaseModel):
    type: Literal[ClientMessageType.AUDIO_FLUSH] = ClientMessageType.AUDIO_FLUSH


class AudioClearPayload(BaseModel):
    type: Literal[ClientMessageType.AUDIO_CLEAR] = ClientMessageType.AUDIO_CLEAR


class PingPayload(BaseModel):
    type: Literal[ClientMessageType.PING] = ClientMessageType.PING


class CancelPayload(BaseModel):
    type: Literal[ClientMessageType.CANCEL] = ClientMessageType.CANCEL


class ServerEnvelope(BaseModel):
    type: ServerMessageType
    session_id: str | None = None
    payload: dict[str, Any] = Field(default_factory=dict)

    def to_json(self) -> dict[str, Any]:
        data: dict[str, Any] = {"type": self.type.value}
        if self.session_id:
            data["session_id"] = self.session_id
        data.update(self.payload)
        return data
