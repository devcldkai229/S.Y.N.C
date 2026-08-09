"""Cấu hình tập trung + Model Registry.

Triết lý "right model for right task": mỗi `ModelTier` map tới một provider/model
cụ thể. Runtime mặc định API-only: OpenAI (mọi tier).
"""
from __future__ import annotations

from enum import Enum
from functools import lru_cache
from urllib.parse import quote

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class ModelTier(str, Enum):
    NANO = "nano"        # detect ngôn ngữ, intent đơn giản, PII classifier
    SMALL = "small"      # smalltalk, FAQ, router
    MID = "mid"          # hội thoại có tool-calling (Coach/Nutrition/Workout)
    LARGE = "large"      # replan, reasoning đa bước, insight
    REALTIME = "realtime"  # voice speech-to-speech
    EMBED = "embed"      # RAG / semantic cache / memory


SENSITIVE_PROVIDER = "openai"
SENSITIVE_FALLBACK_TIER = ModelTier.MID


class ModelSpec:
    """Mô tả một model: provider, tên, và đặc tính dùng cho routing/cost."""

    def __init__(
        self,
        provider: str,
        name: str,
        *,
        supports_tools: bool = True,
        pii_safe: bool = False,
        approx_input_cost_per_1k: float = 0.0,
        approx_output_cost_per_1k: float = 0.0,
        self_hosted: bool = False,
    ) -> None:
        self.provider = provider
        self.name = name
        self.supports_tools = supports_tools
        self.pii_safe = pii_safe
        self.approx_input_cost_per_1k = approx_input_cost_per_1k
        self.approx_output_cost_per_1k = approx_output_cost_per_1k
        self.self_hosted = self_hosted

    def __repr__(self) -> str:  # pragma: no cover
        return f"<ModelSpec {self.provider}:{self.name}>"


# Registry mặc định — API-only (OpenAI). Mọi tier đều pii_safe.
MODEL_REGISTRY: dict[ModelTier, ModelSpec] = {
    ModelTier.NANO: ModelSpec(
        "openai", "gpt-4o-mini", pii_safe=True,
        approx_input_cost_per_1k=0.00015, approx_output_cost_per_1k=0.0006,
    ),
    ModelTier.SMALL: ModelSpec(
        "openai", "gpt-4o-mini", pii_safe=True,
        approx_input_cost_per_1k=0.00015, approx_output_cost_per_1k=0.0006,
    ),
    ModelTier.MID: ModelSpec(
        "openai", "gpt-4o-mini", pii_safe=True,
        approx_input_cost_per_1k=0.00015, approx_output_cost_per_1k=0.0006,
    ),
    ModelTier.LARGE: ModelSpec(
        "openai", "gpt-4o", pii_safe=True,
        approx_input_cost_per_1k=0.0025, approx_output_cost_per_1k=0.01,
    ),
    ModelTier.REALTIME: ModelSpec(
        "openai", "gpt-4o-realtime-preview", supports_tools=True, pii_safe=True,
    ),
    ModelTier.EMBED: ModelSpec(
        "openai", "text-embedding-3-small", supports_tools=False, pii_safe=True,
    ),
}


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Web search
    tavily_api_key: str = ""

    # LLM providers
    openai_api_key: str = ""
    openai_realtime_model: str = "gpt-4o-realtime-preview"
    openai_embedding_model: str = "text-embedding-3-small"
    ollama_base_url: str = "http://localhost:11434"  # optional local extra only

    # .NET internal integration
    internal_api_key: str = "change-me-internal-key"
    iam_base_url: str = "http://localhost:5288"
    roadmap_base_url: str = "http://localhost:5118"
    exercise_base_url: str = "http://localhost:5187"
    nutrition_base_url: str = "http://localhost:5122"
    marketplace_base_url: str = "http://localhost:5119"
    order_base_url: str = "http://localhost:5123"
    payment_base_url: str = "http://localhost:5084"
    notification_base_url: str = "http://localhost:5106"
    social_base_url: str = "http://localhost:5120"

    # Feature flags
    vision_enabled: bool = False
    redis_url: str = "redis://localhost:6379/2"
    postgres_dsn: str = "postgresql://postgres:12345@localhost:5434/sync_ai"

    # Cloud (ECS): password ← Secrets Manager, host/port/user ← SSM. App tự ghép
    # POSTGRES_DSN từ các phần này (xem _compose_postgres_dsn). Local: để trống,
    # dùng thẳng POSTGRES_DSN ở trên.
    db_postgres_host: str = ""
    db_postgres_port: str = "5432"
    db_postgres_user: str = ""
    db_postgres_password: str = ""
    db_postgres_name: str = "sync_ai"

    # JWT
    jwt_issuer: str = "sync-iam"
    jwt_audience: str = "sync-clients"
    jwt_signing_key: str = "shared-with-iam"

    # Observability / cost
    langfuse_host: str = "http://localhost:3000"
    langfuse_public_key: str = ""
    langfuse_secret_key: str = ""
    langfuse_enabled: bool = False
    flow_log_enabled: bool = True
    default_token_budget: int = Field(default=8000)
    premium_token_budget: int = Field(default=12000)
    ultra_token_budget: int = Field(default=16000)
    semantic_cache_enabled: bool = False
    semantic_cache_vector_enabled: bool = False
    semantic_cache_ttl_seconds: int = 86400
    semantic_cache_threshold: float = 0.92

    # Pending write-actions survive next chat turns (confirm button still works).
    pending_action_ttl_seconds: int = 1800

    # Event queue.
    # Prod (AWS): SQS — set AI_SQS_QUEUE_URL → consumer dùng boto3 long-poll.
    # Local/dev: để trống → fallback RabbitMQ (AMQP_URL) hoặc stub.
    ai_sqs_queue_url: str = ""
    aws_region: str = "ap-southeast-1"
    sqs_wait_time_seconds: int = 20
    sqs_max_messages: int = 10
    amqp_url: str = "amqp://sync_mq_user:SyncMqSecurePassword2026@localhost:5672/"

    # Runtime
    environment: str = "development"
    log_level: str = "INFO"
    cors_allowed_origins: str = "*"
    embedding_model: str = "bge-m3"  # legacy; runtime embed dùng openai_embedding_model

    # Rate-limit theo SubscriptionTier (requests / phút)
    rate_limit_enabled: bool = False
    rate_limit_free_per_min: int = 8
    rate_limit_premium_per_min: int = 40
    rate_limit_ultra_per_min: int = 120

    # Intent classification — gpt-4o-mini JSON schema (text scrub, không snapshot)
    intent_classifier_model: str = "gpt-4o-mini"
    intent_classifier_provider: str = "openai"  # openai | ollama (local)
    intent_classifier_timeout_seconds: float = 5.0
    intent_confidence_threshold: float = 0.55
    intent_cache_enabled: bool = True
    intent_cache_ttl_seconds: int = 1800
    intent_classifier_max_tokens: int = 200
    context_snapshot_cache_enabled: bool = True
    context_snapshot_cache_ttl_seconds: int = 300

    @model_validator(mode="after")
    def _compose_postgres_dsn(self) -> "Settings":
        # Chỉ ghép khi có host (cloud); password URL-encode để an toàn ký tự đặc biệt.
        if self.db_postgres_host:
            pwd = quote(self.db_postgres_password, safe="")
            self.postgres_dsn = (
                f"postgresql://{self.db_postgres_user}:{pwd}"
                f"@{self.db_postgres_host}:{self.db_postgres_port}/{self.db_postgres_name}"
            )
        return self

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.cors_allowed_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
