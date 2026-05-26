from sync_agent.application.text_chunking import build_phase1_reply, iter_speech_segments


def test_iter_speech_segments_splits_sentences() -> None:
    text = "Xin chào. " * 15 + "Hôm nay bạn thế nào? " * 15
    segments = iter_speech_segments(text, max_segment_chars=80)
    assert len(segments) >= 2


def test_build_phase1_reply_empty() -> None:
    assert "chưa nghe rõ" in build_phase1_reply("  ").lower()


def test_build_phase1_reply_with_transcript() -> None:
    reply = build_phase1_reply("đổi lịch tập")
    assert "đổi lịch tập" in reply
