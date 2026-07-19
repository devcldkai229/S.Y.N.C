"""Unit tests — intent LLM-degraded, heuristic fast-path."""
from __future__ import annotations

import pytest

from app.graph.intent import (
    classify_intent,
    try_emotional_fast_path,
    try_exercise_fast_path,
    try_heuristic_fast_path,
    try_keyword_fast_path,
    _cacheable_text,
    _degraded,
)


@pytest.mark.asyncio
async def test_empty_intent_defaults_coach():
    result = await classify_intent("")
    assert result.agent == "coach"
    assert result.source == "llm_degraded"


def test_degraded_uses_standard_complexity():
    r = _degraded("đặt món order wallet", "test")
    assert r.agent == "coach"
    assert r.source == "llm_degraded"
    assert r.complexity == "standard"


def test_keyword_create_schedule_today():
    r = try_keyword_fast_path("tao lich tap hom nay")
    assert r is not None
    assert r.agent == "workout"


def test_heuristic_greeting_english():
    r = try_heuristic_fast_path("hello")
    assert r is not None
    assert r.agent == "coach"
    assert r.source == "heuristic"
    assert r.complexity == "simple"


def test_heuristic_greeting_vietnamese():
    r = try_heuristic_fast_path("ê bạn")
    assert r is not None
    assert r.agent == "coach"
    assert r.source == "heuristic"


def test_heuristic_skips_long_or_task_messages():
    assert try_heuristic_fast_path("hom nay an gi de tang co") is None
    assert try_heuristic_fast_path("đổi lịch tập giúp mình với") is None


def test_keyword_workout_no_accent():
    r = try_keyword_fast_path("hom nay tap bai gi vay")
    assert r is not None
    assert r.agent == "workout"
    assert r.source == "heuristic"
    assert r.confidence >= 0.8


def test_keyword_create_roadmap_cyn_auto_message():
    """Exact copy from Flutter aiRoadmapEmptyAutoMessage → workout (not coach)."""
    r = try_keyword_fast_path("Tôi muốn tạo lộ trình theo dõi bởi Cyn!")
    assert r is not None
    assert r.agent == "workout"
    assert r.source == "heuristic"


def test_keyword_create_roadmap_variants():
    for text in (
        "tao lo trinh giup minh",
        "Mình muốn tạo roadmap AI",
        "create roadmap for me",
    ):
        r = try_keyword_fast_path(text)
        assert r is not None, text
        assert r.agent == "workout", text


def test_keyword_nutrition():
    r = try_keyword_fast_path("hom nay an gi de tang co")
    assert r is not None
    assert r.agent == "nutrition"


def test_keyword_commerce_nearby_and_reviews():
    for text in (
        "quán ăn gần đây",
        "quan an gan toi",
        "quán nào bán bún bò gần tôi",
        "review quán X",
        "đánh giá món Y",
        "cho xem thực đơn quán",
        "tim quan gan day rating cao",
    ):
        r = try_keyword_fast_path(text)
        assert r is not None, text
        assert r.agent == "commerce", f"{text} -> {getattr(r, 'agent', None)}"


def test_keyword_ambiguous_returns_none():
    r = try_keyword_fast_path("dat mon tap luyen xong an gi check wallet")
    assert r is None


def test_exercise_bench_press_routes_workout():
    r = try_exercise_fast_path("Bài bench press có phù hợp với mình không?")
    assert r is not None
    assert r.agent == "workout"
    assert r.reason == "exercise_query"


def test_exercise_push_up_technique_routes_workout():
    r = try_exercise_fast_path("Kỹ thuật push up như thế nào?")
    assert r is not None
    assert r.agent == "workout"


def test_exercise_fast_path_skips_nutrition_meal():
    r = try_exercise_fast_path("what should i eat post workout")
    assert r is None


def test_classify_exercise_question_uses_heuristic():
    r = try_keyword_fast_path("Buổi tập hôm nay có push up không? Kỹ thuật sao?")
    assert r is not None
    assert r.agent == "workout"


def test_strip_accents_d():
    from app.text_norm import strip_accents

    assert strip_accents("đ") == "d"


@pytest.mark.asyncio
async def test_classify_hello_uses_heuristic():
    result = await classify_intent("hello")
    assert result.agent == "coach"
    assert result.source == "heuristic"


# ---------------------------------------------------------------------------
# Regression: câu thường không được route nhầm bởi token generic sau bỏ dấu
# (từng gây "hỏi đơn giản mà AI không hiểu": vì/mưa/quần/gần/lát/đường → agent sai)
# ---------------------------------------------------------------------------

def test_keyword_skips_common_vietnamese_words():
    for text in (
        "vì sao vậy?",                # "vi" từng dính commerce
        "hôm nay trời mưa quá",       # "mua" từng dính commerce
        "quần áo mặc đi đâu",         # "quan" từng dính commerce
        "gắn bó lâu dài",             # "gan" từng dính commerce
        "một lát nữa mình hỏi tiếp",  # "lat" từng dính workout
        "chỉ đường giúp mình với",    # "duong" từng dính nutrition
    ):
        assert try_keyword_fast_path(text) is None, text
        assert try_exercise_fast_path(text) is None, text


def test_keyword_wallet_balance_still_routes_commerce():
    r = try_keyword_fast_path("so du vi con bao nhieu")
    assert r is not None
    assert r.agent == "commerce"


def test_keyword_nutrition_dinh_duong_phrase():
    r = try_keyword_fast_path("tu van dinh duong giup minh")
    assert r is not None
    assert r.agent == "nutrition"


def test_emotional_skips_common_words():
    for text in (
        "thời gian này bận quá",   # "gian" từng dính emotional
        "lúc nào cũng vậy",        # "luc" từng dính emotional
        "so sánh 2 bài này",       # "so" từng dính emotional
        "chân mình hơi mỏi",       # "chan" từng dính emotional
        "5 mét nữa là tới",        # "met" từng dính emotional
    ):
        assert try_emotional_fast_path(text) is None, text


def test_emotional_still_detects_real_distress():
    for text in ("dạo này mình stress quá", "mệt mỏi quá muốn bỏ cuộc", "buồn quá bạn ơi"):
        r = try_emotional_fast_path(text)
        assert r is not None, text
        assert r.agent == "coach"
        assert r.complexity == "standard"  # đủ mạnh để đồng cảm, không rơi small


def test_low_confidence_never_drops_to_toolless_small():
    """Tier small = không tools. Không chắc ý user → phải giữ mid + tools."""
    r = _degraded("giúp mình với")
    assert r.tier_for_reply().value == "mid"


def test_greeting_still_uses_small_tier():
    r = try_heuristic_fast_path("hello")
    assert r is not None
    assert r.tier_for_reply().value == "small"


def test_intent_cache_skips_short_followups():
    # Follow-up ngắn phụ thuộc ngữ cảnh hội thoại — không dùng cache chung.
    assert not _cacheable_text("sao vậy?")
    assert not _cacheable_text("ok tiếp đi")
    assert _cacheable_text("hom nay an gi de tang co bap")
