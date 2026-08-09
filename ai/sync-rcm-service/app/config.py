"""Application settings loaded from environment / .env.

Mirrors the conventions of the .NET services (same JWT secret/issuer/audience
from configs/appsettings.Shared.Development.json) so JWTs minted by IAM validate
here too. LLM + embeddings align with sync-agent-service (OpenAI).
"""
from functools import lru_cache
from urllib.parse import quote

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # --- Database (pgvector) ---
    database_url: str = (
        "postgresql+asyncpg://postgres:12345@localhost:5434/sync_ai_agent"
    )

    # Cloud (ECS): password ← Secrets Manager, host/port/user ← SSM. App tự ghép
    # DATABASE_URL (asyncpg) từ các phần này. Local: để trống, dùng database_url trên.
    db_postgres_host: str = ""
    db_postgres_port: str = "5432"
    db_postgres_user: str = ""
    db_postgres_password: str = ""
    db_postgres_name: str = "sync_ai_agent"

    @model_validator(mode="after")
    def _compose_database_url(self) -> "Settings":
        if self.db_postgres_host:
            pwd = quote(self.db_postgres_password, safe="")
            self.database_url = (
                f"postgresql+asyncpg://{self.db_postgres_user}:{pwd}"
                f"@{self.db_postgres_host}:{self.db_postgres_port}/{self.db_postgres_name}"
            )
        return self

    # --- OpenAI (chat + embeddings; same provider as sync-agent-service) ---
    openai_api_key: str = ""
    openai_base_url: str = "https://api.openai.com/v1"
    openai_model: str = "gpt-4o-mini"
    openai_embedding_model: str = "text-embedding-3-small"

    # --- JWT (same values as appsettings.Shared.Development.json) ---
    jwt_secret_key: str = "uANeK_nCAd:N$p2_<&C5?V|#5HDX4vMfIe1)lOf^{_{"
    jwt_issuer: str = "sync-lifestyle-iam-dev"
    jwt_audience: str = "sync-lifestyle-clients-dev"
    jwt_algorithm: str = "HS256"

    # --- Inter-service URLs (direct, not via gateway) ---
    exercise_service_url: str = "http://localhost:5187"
    iam_service_url: str = "http://localhost:5288"
    roadmap_service_url: str = "http://localhost:5118"

    # --- Embedding (OpenAI text-embedding-3-small = 1536 dims) ---
    embedding_dim: int = 1536
    embedding_top_k: int = 12

    # --- Rate limiting ---
    monthly_ai_request_limit: int = 1000


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
