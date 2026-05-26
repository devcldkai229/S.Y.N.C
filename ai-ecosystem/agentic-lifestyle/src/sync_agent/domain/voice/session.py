import asyncio
from dataclasses import dataclass, field
from enum import Enum, auto
from uuid import uuid4

from sync_agent.domain.voice.buffer import AudioBuffer
from sync_agent.domain.voice.protocol import AudioFormat


class VoiceSessionState(Enum):
    CONNECTED = auto()
    BOUND = auto()
    RECORDING = auto()
    PROCESSING = auto()
    CLOSED = auto()


@dataclass
class VoiceSession:
    """Per-WebSocket connection state."""

    connection_id: str = field(default_factory=lambda: str(uuid4()))
    user_id: str | None = None
    session_id: str | None = None
    bearer_token: str | None = None
    state: VoiceSessionState = VoiceSessionState.CONNECTED
    audio_format: AudioFormat = field(default_factory=AudioFormat)
    buffer: AudioBuffer | None = None
    pipeline_task: asyncio.Task[None] | None = None
    lock: asyncio.Lock = field(default_factory=asyncio.Lock)

    def bind(
        self,
        *,
        user_id: str,
        session_id: str,
        audio_format: AudioFormat,
        max_buffer_bytes: int,
        sample_width_bytes: int,
        bearer_token: str | None = None,
    ) -> None:
        self.user_id = user_id
        self.session_id = session_id
        self.bearer_token = bearer_token
        self.audio_format = audio_format
        self.buffer = AudioBuffer(
            sample_rate=audio_format.sample_rate,
            channels=audio_format.channels,
            sample_width_bytes=sample_width_bytes,
            max_bytes=max_buffer_bytes,
        )
        self.state = VoiceSessionState.BOUND

    def ensure_buffer(self) -> AudioBuffer:
        if self.buffer is None:
            raise RuntimeError("Session not bound — send session.bind first")
        return self.buffer

    def mark_recording(self) -> None:
        if self.state in (VoiceSessionState.BOUND, VoiceSessionState.RECORDING):
            self.state = VoiceSessionState.RECORDING

    def mark_processing(self) -> None:
        self.state = VoiceSessionState.PROCESSING

    def mark_idle(self) -> None:
        if self.state != VoiceSessionState.CLOSED:
            self.state = VoiceSessionState.BOUND

    def close(self) -> None:
        self.state = VoiceSessionState.CLOSED
        if self.pipeline_task and not self.pipeline_task.done():
            self.pipeline_task.cancel()
