from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(frozen=True)
class TranscriptionResult:
    text: str
    language: str | None = None
    duration_sec: float | None = None


class SpeechToTextPort(ABC):
    @abstractmethod
    async def transcribe_wav(
        self,
        wav_bytes: bytes,
        *,
        language: str | None = None,
    ) -> TranscriptionResult:
        """Transcribe WAV audio bytes to text."""
