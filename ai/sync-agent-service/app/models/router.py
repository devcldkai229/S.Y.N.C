"""Model Router — chọn LLM theo tier, provider policy (DeepSeek vs OpenAI).

- Tier nano/small  -> DeepSeek (non-sensitive chat + intent)
- Tier mid/large   -> OpenAI (tool-calling + biometric prompts)
- sensitive=True   -> ép OpenAI; fail-safe nếu DeepSeek bị chọn nhầm
"""
from __future__ import annotations

from functools import lru_cache
from typing import Any

from app.config import (
    MODEL_REGISTRY,
    SENSITIVE_FALLBACK_TIER,
    SENSITIVE_PROVIDER,
    ModelSpec,
    ModelTier,
    get_settings,
)

_ESCALATION_ORDER = [
    ModelTier.NANO,
    ModelTier.SMALL,
    ModelTier.MID,
    ModelTier.LARGE,
]


def escalate(tier: ModelTier, steps: int = 1) -> ModelTier:
    if tier not in _ESCALATION_ORDER:
        return tier
    idx = min(_ESCALATION_ORDER.index(tier) + steps, len(_ESCALATION_ORDER) - 1)
    return _ESCALATION_ORDER[idx]


def _coerce_tier(tier: ModelTier | str) -> ModelTier:
    if isinstance(tier, str):
        return ModelTier(tier)
    return tier


def _assert_safe(spec: ModelSpec, sensitive: bool) -> None:
    if sensitive and spec.provider == "deepseek":
        raise ValueError("BIOMETRIC không được gửi tới DeepSeek")


def resolve_tier(tier: ModelTier | str, sensitive: bool = False) -> ModelTier:
    """Chọn tier sau khi áp policy sensitive (nâng lên OpenAI tier nếu cần)."""
    t = _coerce_tier(tier)
    if sensitive and MODEL_REGISTRY[t].provider != SENSITIVE_PROVIDER:
        return SENSITIVE_FALLBACK_TIER
    return t


def resolve_spec(tier: ModelTier | str, sensitive: bool = False) -> ModelSpec:
    """Resolve tier + spec; gọi fail-safe trước khi build client."""
    resolved = resolve_tier(tier, sensitive)
    spec = MODEL_REGISTRY[resolved]
    _assert_safe(spec, sensitive)
    return spec


@lru_cache(maxsize=None)
def _build_chat_client(tier: ModelTier, streaming: bool = True) -> Any:
    """Khởi tạo LangChain chat model theo provider. Lazy + cached.

    Use streaming=False for nested planners so astream_events does not
    forward their tokens to the chat SSE.
    """
    spec: ModelSpec = MODEL_REGISTRY[tier]
    settings = get_settings()

    if spec.provider == "deepseek":
        from langchain_openai import ChatOpenAI

        return ChatOpenAI(
            model=spec.name,
            api_key=settings.deepseek_api_key,
            base_url=settings.deepseek_base_url,
            temperature=0.3,
            streaming=streaming,
        )

    if spec.provider == "ollama":
        from langchain_ollama import ChatOllama  # optional: pip install .[local]

        return ChatOllama(
            model=spec.name,
            base_url=settings.ollama_base_url,
            temperature=0.3,
        )

    if spec.provider == "openai":
        from langchain_openai import ChatOpenAI

        return ChatOpenAI(
            model=spec.name,
            api_key=settings.openai_api_key,
            temperature=0.4,
            streaming=streaming,
        )

    raise ValueError(f"Provider không hỗ trợ: {spec.provider}")


def get_chat_model(
    tier: ModelTier | str,
    *,
    tools: list[Any] | None = None,
    sensitive: bool = False,
) -> Any:
    """Trả về chat model đã (tuỳ chọn) bind tools."""
    resolved = resolve_tier(tier, sensitive)
    spec = resolve_spec(resolved, sensitive)
    model = _build_chat_client(resolved)
    if tools and spec.supports_tools and hasattr(model, "bind_tools"):
        return model.bind_tools(tools)
    return model


def estimate_cost(tier: ModelTier, input_tokens: int, output_tokens: int) -> float:
    spec = MODEL_REGISTRY[tier]
    return (
        input_tokens / 1000 * spec.approx_input_cost_per_1k
        + output_tokens / 1000 * spec.approx_output_cost_per_1k
    )


def _classifier_effective_provider(s: Any) -> str:
    """Provider thực dùng cho classifier.

    Cấu hình mặc định là openai/gpt-4o-mini; nếu KHÔNG có OpenAI key thì
    classifier sẽ chết ở invoke-time mỗi turn (intent_llm_failed → degraded).
    Chat chính chạy deepseek nên tự chuyển classifier sang deepseek khi đó.
    """
    provider = s.intent_classifier_provider
    if provider == "openai" and not (s.openai_api_key or "").strip():
        if (s.deepseek_api_key or "").strip():
            return "deepseek"
    return provider


def _build_deepseek_classifier(s: Any, model_name: str) -> Any:
    from langchain_openai import ChatOpenAI

    return ChatOpenAI(
        model=model_name,
        api_key=s.deepseek_api_key,
        base_url=s.deepseek_base_url,
        temperature=0,
        max_tokens=s.intent_classifier_max_tokens,
    )


@lru_cache(maxsize=1)
def get_classifier_model() -> Any:
    """Intent classifier — structured JSON; mặc định gpt-4o-mini, tự fallback deepseek."""
    s = get_settings()
    provider = _classifier_effective_provider(s)
    if provider == "deepseek":
        # Nếu là auto-fallback từ openai thì intent_classifier_model vẫn là tên
        # model OpenAI → dùng deepseek-chat.
        model_name = (
            s.intent_classifier_model
            if s.intent_classifier_provider == "deepseek"
            else "deepseek-chat"
        )
        return _build_deepseek_classifier(s, model_name)
    if provider == "ollama":
        from langchain_ollama import ChatOllama

        return ChatOllama(
            model=s.intent_classifier_model,
            base_url=s.ollama_base_url,
            temperature=0,
            format="json",
            num_predict=s.intent_classifier_max_tokens,
        )
    if provider == "openai":
        from langchain_openai import ChatOpenAI

        return ChatOpenAI(
            model=s.intent_classifier_model,
            api_key=s.openai_api_key,
            temperature=0,
            max_tokens=s.intent_classifier_max_tokens,
        )
    raise ValueError(f"intent_classifier_provider không hỗ trợ: {provider}")


@lru_cache(maxsize=1)
def get_classifier_structured_method() -> str:
    """`json_schema` chỉ OpenAI hỗ trợ; deepseek/ollama dùng `json_mode`."""
    s = get_settings()
    return "json_schema" if _classifier_effective_provider(s) == "openai" else "json_mode"


@lru_cache(maxsize=1)
def get_classifier_fallback_model() -> Any | None:
    """Deepseek dự phòng khi classifier chính lỗi runtime (auth/quota/mạng).

    Trả None nếu classifier chính đã là deepseek hoặc không có deepseek key.
    """
    s = get_settings()
    if _classifier_effective_provider(s) == "deepseek":
        return None
    if not (s.deepseek_api_key or "").strip():
        return None
    return _build_deepseek_classifier(s, "deepseek-chat")


@lru_cache(maxsize=128)
def get_bound_tool_model(tier: str, agent: str, sensitive: bool) -> Any:
    """Cache bind_tools cho agent tĩnh (không dùng cho commerce — có closure động)."""
    from app.tools.catalog import tool_schemas, tools_for_agent

    names = tools_for_agent(agent)
    schemas = tool_schemas(names)
    return get_chat_model(tier, tools=schemas or None, sensitive=sensitive)
