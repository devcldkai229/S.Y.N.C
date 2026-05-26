import asyncio
from typing import Any

import structlog
from groq import AsyncGroq

from sync_agent.core.exceptions import SpeechToTextError
from sync_agent.infrastructure.stt.base import SpeechToTextPort, TranscriptionResult

logger = structlog.get_logger(__name__)


class GroqSpeechToText(SpeechToTextPort):
    """Groq Whisper — optimized for low-latency batch transcription per utterance."""

    def __init__(
        self,
        *,
        api_key: str,
        model: str = "whisper-large-v3",
        default_language: str | None = "vi",
    ) -> None:
        self._client = AsyncGroq(api_key=api_key)
        self._model = model
        self._default_language = default_language

    async def transcribe_wav(
        self,
        wav_bytes: bytes,
        *,
        language: str | None = None,
    ) -> TranscriptionResult:
        if not wav_bytes:
            return TranscriptionResult(text="", language=language)

        lang = language if language is not None else self._default_language
        kwargs: dict[str, Any] = {
            "model": self._model,
            "file": ("utterance.wav", wav_bytes, "audio/wav"),
            "response_format": "json",
            "temperature": 0.0,
        }
        if lang:
            kwargs["language"] = lang

        try:
            logger.info(
                "groq.stt.request",
                model=self._model,
                bytes=len(wav_bytes),
                language=lang,
            )
            response = await self._client.audio.transcriptions.create(**kwargs)
        except Exception as exc:
            logger.exception("groq.stt.failed")
            raise SpeechToTextError(f"Groq transcription failed: {exc}") from exc

        text = (getattr(response, "text", None) or "").strip()
        detected_lang = getattr(response, "language", None) or lang
        duration = getattr(response, "duration", None)

        logger.info(
            "groq.stt.complete",
            chars=len(text),
            language=detected_lang,
            duration=duration,
        )
        return TranscriptionResult(
            text=text,
            language=detected_lang,
            duration_sec=float(duration) if duration is not None else None,
        )

    async def aclose(self) -> None:
        close = getattr(self._client, "close", None)
        if callable(close):
            result = close()
            if asyncio.iscoroutine(result):
                await result
