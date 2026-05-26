from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment (prefix: SYNC_)."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        env_prefix="SYNC_",
        extra="ignore",
    )

    app_name: str = "SYNC Agent Gateway"
    debug: bool = False
    host: str = "0.0.0.0"
    port: int = 8100

    # Groq STT
    groq_api_key: str = Field(default="", description="Groq API key (required at runtime)")
    groq_stt_model: str = "whisper-large-v3"
    groq_stt_language: str | None = "vi"

    # TravisVN TTS (OpenAI-compatible)
    tts_base_url: str = "https://tts.travisvn.com/v1"
    tts_api_key: str = "not-needed"
    tts_model: str = "openai-edge-tts"
    tts_voice: str = "vi-VN-HoaiMyNeural"
    tts_response_format: str = "mp3"

    # Audio ingest (Flutter → WebSocket binary frames)
    audio_sample_rate: int = 16_000
    audio_channels: int = 1
    audio_sample_width_bytes: int = 2
    audio_max_buffer_bytes: int = 25 * 1024 * 1024

    # WebSocket
    ws_max_message_bytes: int = 4 * 1024 * 1024
    ws_pipeline_timeout_sec: float = 120.0

    # CORS (dev)
    cors_origins: list[str] = Field(default_factory=lambda: ["*"])

    # SYNC C# Gateway (JIT context HTTP — never connect to core DBs directly)
    gateway_base_url: str = "http://localhost:5057"
    gateway_timeout_sec: float = 15.0
    gateway_max_retries: int = 3
    gateway_retry_backoff_sec: float = 0.5

    # pgvector (Workout RAG only — per .cursorrules)
    pgvector_dsn: str = Field(
        default="postgresql://postgres:12345@localhost:5434/sync_vector",
        description="PostgreSQL DSN with pgvector extension",
    )
    pgvector_exercise_table: str = "exercise_catalog"
    pgvector_embedding_model: str = "BAAI/bge-m3"
    pgvector_embedding_dimensions: int = 1024
    pgvector_search_limit: int = 3
    pgvector_connect_timeout_sec: float = 10.0

    # Agent brain (Phase 4)
    groq_router_model: str = "llama-3.1-8b-instant"
    openai_api_key: str = Field(default="", description="OpenAI API key for workers")
    openai_worker_model: str = "gpt-4o-mini"
    nutrition_guardrail_max_retries: int = 3

    # RabbitMQ (Phase 5 — async commands to C# consumers)
    rabbitmq_url: str = Field(
        default="amqp://sync_mq_user:SyncMqSecurePassword2026@localhost:5672/",
        description="AMQP connection URL",
    )
    rabbitmq_exchange: str = "sync.agent.commands"
    rabbitmq_workout_queue: str = "workout_commands"
    rabbitmq_publish_retries: int = 3
    rabbitmq_retry_backoff_sec: float = 0.4
    rabbitmq_prefetch_count: int = 10
    idempotency_ttl_sec: int = 86_400

    # When false, tool_execution uses NoOp publisher (tests / voice-only dev)
    rabbitmq_enabled: bool = True

    def validate_runtime(self) -> None:
        if not self.groq_api_key.strip():
            raise ValueError("SYNC_GROQ_API_KEY is required")

    def validate_agent_runtime(self) -> None:
        self.validate_runtime()
        if not self.openai_api_key.strip():
            raise ValueError("SYNC_OPENAI_API_KEY is required for agent workers")

    def is_agent_enabled(self) -> bool:
        return bool(self.groq_api_key.strip() and self.openai_api_key.strip())


@lru_cache
def get_settings() -> Settings:
    return Settings()
