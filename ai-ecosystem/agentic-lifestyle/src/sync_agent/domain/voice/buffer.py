import io
import wave
from dataclasses import dataclass, field

from sync_agent.core.exceptions import AudioBufferError


@dataclass
class AudioBuffer:
    """Accumulates PCM chunks until flush; enforces max size (Groq 25MB limit)."""

    sample_rate: int
    channels: int
    sample_width_bytes: int
    max_bytes: int
    _chunks: list[bytes] = field(default_factory=list)
    _total: int = 0

    def append(self, chunk: bytes) -> None:
        if not chunk:
            return
        if self._total + len(chunk) > self.max_bytes:
            raise AudioBufferError(
                f"Audio buffer exceeded {self.max_bytes} bytes "
                f"(received {self._total + len(chunk)})"
            )
        self._chunks.append(chunk)
        self._total += len(chunk)

    @property
    def byte_count(self) -> int:
        return self._total

    @property
    def is_empty(self) -> bool:
        return self._total == 0

    def clear(self) -> None:
        self._chunks.clear()
        self._total = 0

    def to_pcm(self) -> bytes:
        return b"".join(self._chunks)

    def to_wav_bytes(self) -> bytes:
        pcm = self.to_pcm()
        buf = io.BytesIO()
        with wave.open(buf, "wb") as wf:
            wf.setnchannels(self.channels)
            wf.setsampwidth(self.sample_width_bytes)
            wf.setframerate(self.sample_rate)
            wf.writeframes(pcm)
        return buf.getvalue()

    def duration_seconds(self) -> float:
        if self._total == 0:
            return 0.0
        bytes_per_second = self.sample_rate * self.channels * self.sample_width_bytes
        return self._total / bytes_per_second
