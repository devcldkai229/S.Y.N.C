"""Prometheus metrics. Nếu prometheus_client không có -> no-op an toàn."""
from __future__ import annotations

from contextlib import contextmanager
from time import perf_counter

try:
    from prometheus_client import Counter, Histogram

    _ENABLED = True
except Exception:  # pragma: no cover
    _ENABLED = False


if _ENABLED:
    CHAT_TURNS = Counter("ai_chat_turns_total", "Số lượt chat", ["intent", "tier"])
    GUARDRAIL_BLOCKS = Counter("ai_guardrail_blocks_total", "Số lần guardrail chặn", ["kind"])
    CACHE_HITS = Counter("ai_semantic_cache_hits_total", "Số lần cache hit")
    INTENT_CACHE_HITS = Counter("ai_intent_cache_hits_total", "Intent exact-cache hit")
    INTENT_HEURISTIC = Counter("ai_intent_heuristic_total", "Intent fast-path heuristic")
    CONTEXT_CACHE_HITS = Counter("ai_context_cache_hits_total", "IAM snapshot cache hit")
    TURN_LATENCY = Histogram("ai_turn_latency_seconds", "Latency mỗi turn", ["intent"])
    INTENT_CLASSIFY_LATENCY = Histogram(
        "ai_intent_classify_seconds", "Intent LLM classify latency", ["source"],
    )
    LOAD_CONTEXT_LATENCY = Histogram("ai_load_context_seconds", "IAM snapshot load latency", ["source"])
    TOOL_LATENCY = Histogram("ai_tool_latency_seconds", "Latency tool .NET", ["tool"])
    LLM_TOKENS = Counter("ai_llm_tokens_total", "Tokens", ["tier", "direction"])


def inc_turn(intent: str, tier: str) -> None:
    if _ENABLED:
        CHAT_TURNS.labels(intent=intent, tier=tier).inc()


def inc_block(kind: str) -> None:
    if _ENABLED:
        GUARDRAIL_BLOCKS.labels(kind=kind).inc()


def inc_cache_hit() -> None:
    if _ENABLED:
        CACHE_HITS.inc()


def inc_intent_cache_hit() -> None:
    if _ENABLED:
        INTENT_CACHE_HITS.inc()


def inc_intent_heuristic() -> None:
    if _ENABLED:
        INTENT_HEURISTIC.inc()


def inc_context_cache_hit() -> None:
    if _ENABLED:
        CONTEXT_CACHE_HITS.inc()


def add_tokens(tier: str, direction: str, n: int) -> None:
    if _ENABLED:
        LLM_TOKENS.labels(tier=tier, direction=direction).inc(n)


@contextmanager
def time_turn(intent: str):
    start = perf_counter()
    try:
        yield
    finally:
        if _ENABLED:
            TURN_LATENCY.labels(intent=intent).observe(perf_counter() - start)


@contextmanager
def time_tool(tool: str):
    start = perf_counter()
    try:
        yield
    finally:
        if _ENABLED:
            TOOL_LATENCY.labels(tool=tool).observe(perf_counter() - start)


@contextmanager
def time_intent_classify(source: str = "llm"):
    start = perf_counter()
    try:
        yield
    finally:
        if _ENABLED:
            INTENT_CLASSIFY_LATENCY.labels(source=source).observe(perf_counter() - start)


@contextmanager
def time_load_context(source: str = "iam"):
    start = perf_counter()
    try:
        yield
    finally:
        if _ENABLED:
            LOAD_CONTEXT_LATENCY.labels(source=source).observe(perf_counter() - start)
