import re

_SENTENCE_SPLIT = re.compile(r"(?<=[.!?…])\s+")


def iter_speech_segments(text: str, *, max_segment_chars: int = 240) -> list[str]:
    """
    Split assistant text into TTS-friendly segments for incremental streaming.
    Mimics token-by-token LLM output in later LangGraph phases.
    """
    normalized = " ".join(text.split())
    if not normalized:
        return []

    sentences = _SENTENCE_SPLIT.split(normalized)
    segments: list[str] = []
    current = ""

    for sentence in sentences:
        if not sentence:
            continue
        candidate = f"{current} {sentence}".strip() if current else sentence
        if len(candidate) <= max_segment_chars:
            current = candidate
        else:
            if current:
                segments.append(current)
            if len(sentence) <= max_segment_chars:
                current = sentence
            else:
                for i in range(0, len(sentence), max_segment_chars):
                    segments.append(sentence[i : i + max_segment_chars])
                current = ""
    if current:
        segments.append(current)
    return segments


def build_phase1_reply(transcript: str) -> str:
    """Placeholder brain until LangGraph (Phase 2)."""
    text = transcript.strip()
    if not text:
        return "Mình chưa nghe rõ. Bạn nói lại giúp mình nhé?"
    return (
        f"Mình đã nghe bạn nói: «{text}». "
        "Đây là chế độ thử giọng — trợ lý AI đầy đủ sẽ được kết nối ở giai đoạn tiếp theo."
    )
