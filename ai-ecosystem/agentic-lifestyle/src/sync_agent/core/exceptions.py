class SyncAgentError(Exception):
    """Base error for SYNC agent services."""


class ConfigurationError(SyncAgentError):
    """Missing or invalid configuration."""


class AudioBufferError(SyncAgentError):
    """Audio buffer limits exceeded."""


class SpeechToTextError(SyncAgentError):
    """STT provider failure."""


class TextToSpeechError(SyncAgentError):
    """TTS provider failure."""


class VoiceSessionError(SyncAgentError):
    """Invalid voice session state or protocol violation."""


class SyncApiError(SyncAgentError):
    """HTTP call to SYNC C# backend failed."""

    def __init__(self, message: str, *, status_code: int | None = None, url: str | None = None) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.url = url


class JitContextFetchError(SyncAgentError):
    """One or more JIT context sources failed (non-fatal aggregate)."""

    def __init__(self, message: str, *, errors: dict[str, str] | None = None) -> None:
        super().__init__(message)
        self.errors = errors or {}


class EmbeddingError(SyncAgentError):
    """Text embedding generation failed."""


class VectorSearchError(SyncAgentError):
    """pgvector similarity search failed."""


class LLMProviderError(SyncAgentError):
    """Router or worker LLM call failed."""


class GuardrailViolationError(SyncAgentError):
    """Deterministic safety check failed — triggers worker retry."""

    def __init__(self, message: str, *, violations: list[str] | None = None) -> None:
        super().__init__(message)
        self.violations = violations or []


class RabbitMQPublishError(SyncAgentError):
    """Failed to connect or publish to RabbitMQ."""


class ToolExecutionError(SyncAgentError):
    """Tool command publishing failed after retries."""
