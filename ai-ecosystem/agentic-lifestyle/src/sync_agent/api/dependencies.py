from functools import lru_cache

from sync_agent.application.agent_runner import AgentRunner
from sync_agent.application.voice_pipeline import VoicePipeline
from sync_agent.core.config import Settings, get_settings
from sync_agent.infrastructure.stt.groq_provider import GroqSpeechToText
from sync_agent.infrastructure.tts.travis_provider import TravisTextToSpeech

_agent_runner: AgentRunner | None = None


@lru_cache
def get_stt_service() -> GroqSpeechToText:
    settings = get_settings()
    return GroqSpeechToText(
        api_key=settings.groq_api_key,
        model=settings.groq_stt_model,
        default_language=settings.groq_stt_language,
    )


@lru_cache
def get_tts_service() -> TravisTextToSpeech:
    settings = get_settings()
    return TravisTextToSpeech(
        base_url=settings.tts_base_url,
        api_key=settings.tts_api_key,
        model=settings.tts_model,
        voice=settings.tts_voice,
        response_format=settings.tts_response_format,
    )


def get_agent_runner() -> AgentRunner | None:
    """Lazy singleton; None when agent API keys are not configured."""
    global _agent_runner
    settings = get_settings()
    if not settings.is_agent_enabled():
        return None
    if _agent_runner is None:
        _agent_runner = AgentRunner.from_settings(settings)
    return _agent_runner


def get_voice_pipeline() -> VoicePipeline:
    settings = get_settings()
    return VoicePipeline(
        stt=get_stt_service(),
        tts=get_tts_service(),
        settings=settings,
        agent_runner=get_agent_runner(),
    )


def get_app_settings() -> Settings:
    return get_settings()
