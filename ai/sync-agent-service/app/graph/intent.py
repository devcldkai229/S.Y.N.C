"""Intent classification — cache, keyword/greeting fast-path, LLM JSON classify.

  1. Cache Redis (exact-match) -> O(1) for repeats.
  2. Keyword fast-path (workout/nutrition/commerce/insight) -> skip LLM.
  3. Greeting heuristic (≤3 từ) -> coach.
  4. LLM JSON classify (gpt-4o-mini structured).
  5. On failure -> default coach (llm_degraded), never crash the turn.
"""
from __future__ import annotations

import asyncio
import hashlib
import json
import re
from typing import Any, Literal

from pydantic import BaseModel, Field, field_validator

from app.config import ModelTier, get_settings
from app.logging_setup import get_logger
from app.observability import metrics
from app.observability.flow_log import flow
from app.prompts.intent import AGENT_CATALOG, INTENT_PROMPT_VERSION, build_intent_messages
from app.text_norm import has_vietnamese_diacritics, strip_accents

_log = get_logger("ai.intent")

AgentName = Literal["coach", "nutrition", "workout", "commerce", "insight"]
_VALID_AGENTS = set(AGENT_CATALOG.keys())

_COMPLEXITY_TIER = {
    "simple": ModelTier.SMALL,
    "standard": ModelTier.MID,
    "complex": ModelTier.LARGE,
}

_GREETING_TOKENS = frozenset({
    "hello", "hi", "hey", "yo", "helo", "halo", "alo",
    "ok", "okay", "okie", "uk", "oke", "thanks", "thank", "you", "thx",
    "chao", "xin", "cam", "on", "camon", "ơn", "cảm",
    "e", "ê", "oi", "ơi", "ban", "bạn", "nha", "nhe", "nhé", "nhá",
    "good", "morning", "afternoon", "evening", "bye", "goodbye", "bb",
    "a", "ah", "uh", "hmm", "hm",
})

# Emotional / wellbeing tokens — route to coach with standard tier (not small)
# so the model is smart enough to empathize without mixing in fitness context.
# Matching runs on accent-STRIPPED text, so entries here must be accent-free and
# unambiguous after stripping. Bare tokens like "lo/so/gian/luc/met/chan" match
# vô số từ thường ("lúc", "thời gian", "so sánh", "5 mét") → chỉ giữ token đơn
# thật sự không nhập nhằng; phần tiếng Việt đa nghĩa chuyển hết sang phrases.
_EMOTIONAL_TOKENS = frozenset({
    "stress", "stressed", "sad", "anxious", "depressed", "overwhelmed",
    "lonely", "khoc",
})

_EMOTIONAL_PHRASES = (
    "stress qua", "buon qua", "met qua", "chan qua", "met moi qua",
    "ap luc qua", "kiet suc", "lo lang", "lo qua", "cang thang",
    "khong vui", "muon khoc", "nan chi", "nan long", "bat luc",
    "chan nan", "tuyet vong", "that vong qua", "thay co don", "cam thay co don",
    "cam thay te", "muon bo cuoc", "noi chuyen chut",
    "tam su", "can noi chuyen",
    "feeling down", "so stressed", "feel bad", "feel so bad",
)

# Keyword maps — accent-stripped matching (lóng VN + EN).
_KEYWORD_PHRASES: dict[str, tuple[str, ...]] = {
    "workout": (
        "lich tap", "buoi tap", "bai tap", "hom nay tap", "tap bai",
        "tap hom nay", "doi lich tap", "request replan", "today workout",
        "workout plan", "exercise plan",
        "push up", "pull up", "bench press", "hit dat", "keo xa",
        "ky thuat", "cach tap", "form tap", "technique",
        # Tạo / quản lý PersonalizedRoadmap (onboarding từ tab AI Roadmap)
        "tao lo trinh", "lo trinh", "tao roadmap", "create roadmap",
        "theo doi boi cyn", "lo trinh cyn", "lo trinh theo doi",
        "personalized roadmap", "ai roadmap",
        "tao lich", "tao lich tap", "len lich", "len lich tap",
        "tao lich hom nay", "lich tap hom nay",
    ),
    "nutrition": (
        "an gi", "hom nay an", "bao nhieu calo", "bao nhieu protein",
        "log meal", "log bua", "ghi bua", "macro hom nay", "meal plan",
        "post workout meal", "what should i eat", "dinh duong",
        "uong nuoc", "nuoc uong", "du nuoc", "bao nhieu nuoc",
    ),
    "commerce": (
        "dat mon", "dat giup", "dat gium", "dat giup mon", "dat don",
        "don hang", "check wallet", "so du vi", "so du", "trong vi",
        "topup", "nap vi", "nap tien",
        "track order", "theo doi don", "mua mon", "mua giup", "mua do an",
        "order food",
        "quan an", "nha hang", "gan day", "gan toi", "gan minh",
        "review quan", "danh gia quan", "danh gia mon", "thuc don",
        "menu quan", "rating quan", "quan nao", "quan ban", "tim quan",
        "quan gan", "doi tac",
        # KHÔNG thêm "co ban" ("có bán") — đụng "cơ bản"; câu "có bán X không"
        # để LLM classify (đã có few-shot).
        "them vao cart", "them vao gio", "gio hang", "xem gio hang",
        "tim mon", "mua o dau", "goi y mon",
    ),
    "insight": (
        "tien do", "burnout", "plateau", "weekly report", "bao cao tuan",
        "adherence", "progress trend", "thong ke", "phan tich tien do",
        "overtraining", "qua tai", "bieu do", "du doan", "xu huong",
    ),
}

# Token đơn phải KHÔNG nhập nhằng sau khi bỏ dấu. Tuyệt đối không đưa vào đây
# các từ trần kiểu "dat/mua/vi/quan/gan/lat/dinh/duong/nuoc" — chúng khớp cả
# "đạt/mưa/vì/quần/gần/lát/đỉnh/đường/nước..." khiến câu thường bị route nhầm
# với confidence 0.88 (bỏ qua LLM). Trường hợp đa nghĩa → dùng _KEYWORD_PHRASES.
_KEYWORD_TOKENS: dict[str, frozenset[str]] = {
    "workout": frozenset({
        "tap", "gym", "reps", "rep", "set", "sets", "workout",
        "exercise", "replan", "roadmap", "recovery", "deload", "cardio",
        "squat", "deadlift", "bench", "plank", "lunge", "burpee", "row",
        "curl", "dip", "overhead", "tricep", "bicep", "pushup",
        "pullup", "crunch", "kettlebell", "snatch", "clean", "jerk",
    }),
    "nutrition": frozenset({
        "calo", "calorie", "calories", "protein", "carb", "carbs", "fat",
        "macro", "macros", "meal", "meals", "food", "eat", "eating",
        "water", "bua",
    }),
    "commerce": frozenset({
        "wallet", "order", "voucher", "checkout", "payment", "topup",
        "reorder", "affiliate", "partner", "menu", "cart",
        "coin", "coins", "vnd", "review", "rating", "thucdon",
        "danhgia", "nhahang",
    }),
    "insight": frozenset({
        "trend", "trends", "stats", "statistics", "report", "analytics",
        "burnout", "plateau", "adherence", "insight", "score", "scores",
    }),
}


class IntentLLMOutput(BaseModel):
    agent: AgentName = "coach"
    language: Literal["vi", "en"] = "vi"
    complexity: Literal["simple", "standard", "complex"] = "standard"
    confidence: float = Field(default=0.5, ge=0.0, le=1.0)
    reason: str = ""


class IntentResult(BaseModel):
    agent: AgentName = "coach"
    language: Literal["vi", "en"] = "vi"
    complexity: Literal["simple", "standard", "complex"] = "standard"
    confidence: float = Field(default=0.5, ge=0.0, le=1.0)
    reason: str = ""
    source: Literal["llm", "cache", "llm_degraded", "heuristic"] = "llm"

    @field_validator("agent", mode="before")
    @classmethod
    def _coerce_agent(cls, v: object) -> str:
        s = str(v).strip().lower()
        return s if s in _VALID_AGENTS else "coach"

    def tier_for_reply(self) -> ModelTier:
        # Tier `small` chạy KHÔNG tools + history bị cắt (runner.py) — chỉ dành cho
        # greeting/simple đã chắc chắn. Confidence thấp nghĩa là ta KHÔNG chắc user
        # muốn gì → càng cần model đủ khả năng + tools để tự làm rõ, không phải
        # model yếu nhất. Vì vậy low-confidence ép về MID thay vì SMALL.
        thr = get_settings().intent_confidence_threshold
        if self.confidence < thr:
            return ModelTier.MID
        return _COMPLEXITY_TIER.get(self.complexity, ModelTier.MID)


def _normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip().lower())


def _match_text(text: str) -> str:
    """Chuẩn hoá để match keyword: bỏ dấu, bỏ ký tự không chữ-số, gộp space."""
    flat = strip_accents(_normalize(text))
    flat = re.sub(r"[^a-z0-9\s]", " ", flat)
    return re.sub(r"\s+", " ", flat).strip()


def _has_phrase(norm: str, phrase: str) -> bool:
    """Match phrase theo RANH GIỚI TỪ — substring trần khớp nhầm giữa từ
    (vd "an gi" nằm trong "dan giup")."""
    return f" {phrase} " in f" {norm} "


def _has_any_phrase(norm: str, phrases: tuple[str, ...]) -> bool:
    return any(_has_phrase(norm, p) for p in phrases)


def _cache_key(text: str) -> str:
    h = hashlib.sha1(_normalize(text).encode("utf-8")).hexdigest()
    return f"ai:intent:{INTENT_PROMPT_VERSION}:{h}"


# Cache key chỉ hash text, nhưng LLM classify dùng cả recent_context. Câu ngắn
# ("sao vậy?", "tiếp đi") là follow-up phụ thuộc hội thoại — cache chung sẽ
# replay intent của hội thoại khác. Chỉ cache câu đủ dài + kết quả đủ tự tin.
_CACHE_MIN_TOKENS = 4
_CACHE_MIN_CONFIDENCE = 0.7


def _cacheable_text(text: str) -> bool:
    tokens = re.findall(r"[\w']+", strip_accents(_normalize(text)))
    return len(tokens) >= _CACHE_MIN_TOKENS


async def _cache_get(text: str) -> IntentResult | None:
    from app.deps import get_redis

    s = get_settings()
    if not s.intent_cache_enabled:
        return None
    r = get_redis()
    if r is None:
        return None
    try:
        raw = await r.get(_cache_key(text))
        if raw:
            data = json.loads(raw)
            data["source"] = "cache"
            return IntentResult(**data)
    except Exception:  # pragma: no cover
        return None
    return None


async def _cache_put(text: str, result: IntentResult) -> None:
    from app.deps import get_redis

    s = get_settings()
    if not s.intent_cache_enabled:
        return
    if not _cacheable_text(text) or result.confidence < _CACHE_MIN_CONFIDENCE:
        return
    r = get_redis()
    if r is None:
        return
    try:
        payload = result.model_dump()
        payload["source"] = "llm"
        await r.set(_cache_key(text), json.dumps(payload), ex=s.intent_cache_ttl_seconds)
    except Exception:  # pragma: no cover
        pass


_VI_MARKERS = frozenset({
    "hom", "nay", "gi", "vay", "the", "nao", "bao", "nhieu", "minh", "ban",
    "gium", "giup", "khong", "nha", "nhe", "oi", "duoc", "roi", "voi", "cho",
    "lam", "sao", "an", "tap", "dat", "muon", "can", "tui", "toi",
})
_EN_MARKERS = frozenset({
    "the", "what", "how", "should", "my", "is", "are", "want", "need", "today",
    "workout", "eat", "order", "please", "can", "you", "me", "for", "and",
})


def _detect_lang(text: str) -> Literal["vi", "en"]:
    if has_vietnamese_diacritics(text):
        return "vi"
    tokens = set(re.findall(r"[a-z]+", strip_accents(text)))
    vi_hits = len(tokens & _VI_MARKERS)
    en_hits = len(tokens & _EN_MARKERS)
    if vi_hits > 0 and vi_hits >= en_hits:
        return "vi"
    if en_hits >= 2 and vi_hits == 0:
        return "en"
    return "vi"


def _degraded(text: str, reason: str = "llm_unavailable") -> IntentResult:
    # standard → mid tier + tools available (avoid small/empty-tools on task-like text)
    return IntentResult(
        agent="coach",
        language=_detect_lang(text),
        complexity="standard",
        confidence=0.3,
        reason=reason,
        source="llm_degraded",
    )


def _agents_from_keywords(text: str) -> set[str]:
    matched: set[str] = set()
    norm = _match_text(text)
    tokens = set(norm.split())
    for agent, phrases in _KEYWORD_PHRASES.items():
        if _has_any_phrase(norm, phrases):
            matched.add(agent)
    for agent, kws in _KEYWORD_TOKENS.items():
        if tokens & kws:
            matched.add(agent)
    return matched


_NUTRITION_EXERCISE_OVERRIDE_PHRASES = (
    "an gi", "hom nay an", "log meal", "log bua", "ghi bua",
    "post workout meal", "what should i eat", "meal plan", "macro hom nay",
)

_EXERCISE_PHRASES = (
    "push up", "pull up", "bench press", "lat pulldown", "hip thrust",
    "hit dat", "keo xa", "gac chan", "ky thuat", "cach tap",
    "form tap", "proper form", "good form",
)

# "lat" cố tình KHÔNG có ở đây ("một lát nữa") — "lat pulldown" đã có trong
# _EXERCISE_PHRASES nên vẫn bắt được câu hỏi về bài lat.
_EXERCISE_TOKENS = frozenset({
    "squat", "deadlift", "bench", "plank", "lunge", "burpee", "row",
    "curl", "dip", "overhead", "tricep", "bicep", "pushup",
    "pullup", "crunch", "kettlebell", "snatch", "clean", "jerk", "situp",
})


def _mentions_exercise(text: str) -> bool:
    norm = _match_text(text)
    if _has_any_phrase(norm, _EXERCISE_PHRASES):
        return True
    return bool(set(norm.split()) & _EXERCISE_TOKENS)


def _mentions_nutrition_intent(text: str) -> bool:
    norm = _match_text(text)
    if _has_any_phrase(norm, _NUTRITION_EXERCISE_OVERRIDE_PHRASES):
        return True
    agents = _agents_from_keywords(text)
    return "nutrition" in agents and "workout" not in agents


def try_exercise_fast_path(text: str) -> IntentResult | None:
    """Câu hỏi về bài tập cụ thể (tên, kỹ thuật, phù hợp) → workout, trừ khi rõ ràng là dinh dưỡng."""
    if not text or not text.strip():
        return None
    if not _mentions_exercise(text):
        return None
    if _mentions_nutrition_intent(text):
        return None
    lang = _detect_lang(text)
    return IntentResult(
        agent="workout",
        language=lang,
        complexity="standard",
        confidence=0.91,
        reason="exercise_query",
        source="heuristic",
    )


_COMMERCE_DISCOVERY_PHRASES = (
    "quan an", "nha hang", "gan day", "gan toi", "gan minh",
    "review quan", "danh gia quan", "danh gia mon", "thuc don",
    "menu quan", "rating quan", "quan nao", "quan ban", "tim quan",
    "quan gan", "doi tac",
    # Tìm/mua/giỏ hàng món THẬT trên Sync — thắng nutrition để không bịa món generic.
    "them vao cart", "them vao gio", "gio hang", "tim mon",
    "mua o dau", "goi y mon", "dat mon", "mua mon",
)

# Thống kê/biểu đồ/dự đoán ĐA KỲ thắng nutrition/workout khi overlap
# (vd "thống kê dinh dưỡng 2 tuần" phải vào insight để vẽ chart, không phải nutrition).
_INSIGHT_STATS_PHRASES = (
    "thong ke", "bieu do", "du doan", "bao cao tuan", "xu huong",
    "tien do", "progress trend", "phan tich tien do",
)

# Câu ĐÁNH GIÁ dinh dưỡng/tập luyện theo NHIỀU NGÀY → insight tự chủ động thống kê
# (vd "dinh dưỡng mấy ngày nay thế nào rồi", "tuần này ăn uống ra sao", "nhận xét chế độ ăn").
_STATS_CONTEXT_PHRASES = (
    "dinh duong", "an uong", "che do an", "an kieng", "calo", "macro",
    "tap luyen", "tien do", "the luc",
)
_STATS_PERIOD_PHRASES = (
    "may ngay nay", "may hom nay", "may bua nay", "nhung ngay qua", "thoi gian qua",
    "tuan nay", "tuan qua", "thang nay", "thang qua", "dao nay", "gan day",
)
# Đánh giá mạnh: chỉ cần kèm ngữ cảnh dinh dưỡng/tập là đủ.
_STATS_STRONG_EVAL = ("danh gia", "nhan xet", "tong quan", "thong ke", "review")
# Đánh giá nhẹ: cần kèm mốc thời gian đa kỳ mới coi là thống kê.
_STATS_SOFT_EVAL = ("the nao", "ra sao", "sao roi", "on khong", "co on", "nhu the nao")


def _is_eval_stats_query(norm: str) -> bool:
    """Câu nhận xét/thống kê dinh dưỡng·tập luyện đa kỳ → nên đưa vào insight."""
    if not _has_any_phrase(norm, _STATS_CONTEXT_PHRASES):
        return False
    if _has_any_phrase(norm, _STATS_STRONG_EVAL):
        return True
    return _has_any_phrase(norm, _STATS_SOFT_EVAL) and _has_any_phrase(norm, _STATS_PERIOD_PHRASES)


def try_keyword_fast_path(text: str) -> IntentResult | None:
    """Khớp keyword rõ ràng cho 4 agent chuyên biệt — không đa nghĩa."""
    if not text or not text.strip():
        return None
    agents = _agents_from_keywords(text)
    norm = _match_text(text)
    # Stats đa kỳ thắng miền dữ liệu (nutrition/workout) khi overlap.
    if "insight" in agents and len(agents) > 1 and _has_any_phrase(norm, _INSIGHT_STATS_PHRASES):
        agents = {"insight"}
    # Câu đánh giá/nhận xét dinh dưỡng·tập luyện đa kỳ → insight tự thống kê.
    elif _is_eval_stats_query(norm):
        agents = {"insight"}
    # Discovery quán/review/giỏ hàng thắng nutrition khi overlap (vd. "quán ăn gần đây").
    if "commerce" in agents and "nutrition" in agents:
        if _has_any_phrase(norm, _COMMERCE_DISCOVERY_PHRASES):
            agents.discard("nutrition")
    if len(agents) != 1:
        return None
    agent = next(iter(agents))
    lang = _detect_lang(text)
    return IntentResult(
        agent=agent,  # type: ignore[arg-type]
        language=lang,
        complexity="standard",
        confidence=0.88,
        reason="keyword",
        source="heuristic",
    )


def try_heuristic_fast_path(text: str) -> IntentResult | None:
    """Câu ≤3 từ, toàn greeting/ack → coach/simple, bỏ qua LLM."""
    norm = _normalize(text)
    if not norm:
        return None
    tokens = re.findall(r"[\w']+", strip_accents(norm))
    if not tokens or len(tokens) > 3:
        return None
    lowered = {t.lower() for t in tokens}
    if not lowered.issubset(_GREETING_TOKENS):
        return None
    lang = _detect_lang(text)
    return IntentResult(
        agent="coach",
        language=lang,
        complexity="simple",
        confidence=0.98,
        reason="greeting",
        source="heuristic",
    )


def try_emotional_fast_path(text: str) -> IntentResult | None:
    """Phát hiện cảm xúc/wellbeing → coach + standard tier (model đủ mạnh để đồng cảm)."""
    norm = _match_text(text)
    if not norm:
        return None

    # Check emotional phrases
    if _has_any_phrase(norm, _EMOTIONAL_PHRASES):
        lang = _detect_lang(text)
        return IntentResult(
            agent="coach",
            language=lang,
            complexity="standard",  # ← standard, NOT simple → tier=mid
            confidence=0.92,
            reason="emotional_support",
            source="heuristic",
        )

    # Check emotional tokens
    tokens = set(re.findall(r"[a-z0-9]+", norm))
    hits = tokens & _EMOTIONAL_TOKENS
    if len(hits) >= 1:
        lang = _detect_lang(text)
        return IntentResult(
            agent="coach",
            language=lang,
            complexity="standard",
            confidence=0.90,
            reason="emotional_support",
            source="heuristic",
        )


async def _llm_classify(text: str, recent_context: str | None) -> IntentResult:
    from app.models.router import (
        get_classifier_model,
        get_classifier_structured_method,
    )

    messages = build_intent_messages(text, recent_context)
    timeout = get_settings().intent_classifier_timeout_seconds

    async def _invoke(model: Any, method: str) -> IntentResult:
        structured = model.with_structured_output(IntentLLMOutput, method=method)
        out: IntentLLMOutput = await asyncio.wait_for(
            structured.ainvoke(messages),
            timeout=timeout,
        )
        return IntentResult(**out.model_dump(), source="llm")

    return await _invoke(get_classifier_model(), get_classifier_structured_method())


def _record_heuristic(result: IntentResult, label: str) -> IntentResult:
    metrics.inc_intent_heuristic()
    with metrics.time_intent_classify("heuristic"):
        pass
    flow(
        f"Intent — {label} → agent={result.agent} | confidence={result.confidence}",
        indent=3,
    )
    return result


async def classify_intent(text: str, recent_context: str | None = None) -> IntentResult:
    """cache -> keyword -> greeting -> LLM -> coach (llm_degraded)."""
    if not text or not text.strip():
        return IntentResult(agent="coach", confidence=1.0, reason="empty", source="llm_degraded")

    cached = await _cache_get(text) if _cacheable_text(text) else None
    if cached is not None:
        metrics.inc_intent_cache_hit()
        with metrics.time_intent_classify("cache"):
            pass
        flow(
            f"Intent — cache HIT → agent={cached.agent} | confidence={cached.confidence}",
            indent=3,
        )
        return cached

    kw = try_keyword_fast_path(text)
    if kw is not None:
        return _record_heuristic(kw, "keyword fast-path")

    exercise = try_exercise_fast_path(text)
    if exercise is not None:
        return _record_heuristic(exercise, "exercise fast-path")

    greeting = try_heuristic_fast_path(text)
    if greeting is not None:
        return _record_heuristic(greeting, "greeting fast-path")

    emotional = try_emotional_fast_path(text)
    if emotional is not None:
        return _record_heuristic(emotional, "emotional fast-path")

    flow("Intent — cache MISS → gọi LLM phân loại", indent=3)
    try:
        with metrics.time_intent_classify("llm"):
            result = await _llm_classify(text, recent_context)
        await _cache_put(text, result)
        flow(
            f"Intent — LLM → agent={result.agent} | lang={result.language} | "
            f"complexity={result.complexity} | confidence={result.confidence} | lý do={result.reason}",
            indent=3,
        )
        return result
    except Exception:
        _log.warning("intent_llm_failed", extra={"node": "intent"})
        # LLM fail: re-try heuristics before coach degrade (keep tools via standard).
        kw2 = try_keyword_fast_path(text)
        if kw2 is not None:
            flow("Intent — LLM lỗi → keyword fallback", indent=3)
            return _record_heuristic(kw2, "keyword after llm fail")
        ex2 = try_exercise_fast_path(text)
        if ex2 is not None:
            flow("Intent — LLM lỗi → exercise fallback", indent=3)
            return _record_heuristic(ex2, "exercise after llm fail")
        flow("Intent — LLM lỗi → fallback coach standard (llm_degraded)", indent=3)
        return _degraded(text)
