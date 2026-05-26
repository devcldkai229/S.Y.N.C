from collections.abc import AsyncIterator

import structlog
from openai import AsyncOpenAI

from sync_agent.core.exceptions import TextToSpeechError
from sync_agent.infrastructure.tts.base import TextToSpeechPort

logger = structlog.get_logger(__name__)


class TravisTextToSpeech(TextToSpeechPort):
    """
    TravisVN Edge TTS — OpenAI-compatible streaming endpoint.
    https://tts.travisvn.com/v1
    """

    def __init__(
        self,
        *,
        base_url: str,
        api_key: str,
        model: str = "openai-edge-tts",
        voice: str = "vi-VN-HoaiMyNeural",
        response_format: str = "mp3",
    ) -> None:
        self._model = model
        self._voice = voice
        self._response_format = response_format
        self._client = AsyncOpenAI(
            api_key=api_key,
            base_url=base_url.rstrip("/"),
        )

    async def stream_speech(self, text: str) -> AsyncIterator[bytes]:
        cleaned = text.strip()
        if not cleaned:
            return

        try:
            logger.info(
                "travis.tts.request",
                model=self._model,
                voice=self._voice,
                chars=len(cleaned),
            )
            async with self._client.audio.speech.with_streaming_response.create(
                model=self._model,
                voice=self._voice,
                input=cleaned,
                response_format=self._response_format,  # type: ignore[arg-type]
            ) as response:
                async for chunk in response.iter_bytes(chunk_size=4096):
                    if chunk:
                        yield chunk
        except Exception as exc:
            logger.exception("travis.tts.failed")
            raise TextToSpeechError(f"TTS streaming failed: {exc}") from exc

    async def aclose(self) -> None:
        await self._client.close()
