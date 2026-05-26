import pytest

from sync_agent.core.exceptions import AudioBufferError
from sync_agent.domain.voice.buffer import AudioBuffer


def test_append_and_wav_roundtrip() -> None:
    buf = AudioBuffer(sample_rate=16_000, channels=1, sample_width_bytes=2, max_bytes=1_000_000)
    buf.append(b"\x00\x01" * 100)
    assert buf.byte_count == 200
    wav = buf.to_wav_bytes()
    assert wav[:4] == b"RIFF"
    assert buf.duration_seconds() > 0


def test_max_bytes_raises() -> None:
    buf = AudioBuffer(sample_rate=16_000, channels=1, sample_width_bytes=2, max_bytes=10)
    buf.append(b"\x00\x01" * 3)
    with pytest.raises(AudioBufferError):
        buf.append(b"\x00\x01" * 3)
