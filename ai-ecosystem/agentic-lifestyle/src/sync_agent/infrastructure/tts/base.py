from abc import ABC, abstractmethod
from collections.abc import AsyncIterator


class TextToSpeechPort(ABC):
    @abstractmethod
    async def stream_speech(self, text: str) -> AsyncIterator[bytes]:
        """Yield encoded audio chunks (e.g. MP3) as they arrive from the provider."""
        ...

    @abstractmethod
    async def aclose(self) -> None:
        """Release HTTP client resources."""
