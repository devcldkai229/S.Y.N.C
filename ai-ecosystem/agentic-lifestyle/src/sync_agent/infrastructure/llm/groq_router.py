"""Fast intent classification via Groq llama-3.1-8b-instant."""

import json

import structlog
from groq import AsyncGroq

from sync_agent.core.config import Settings
from sync_agent.core.exceptions import LLMProviderError
from sync_agent.domain.schemas.agent.intent import AgentIntent

logger = structlog.get_logger(__name__)

_INTENTS = {i.value for i in AgentIntent}


class GroqIntentRouter:
    def __init__(self, *, settings: Settings) -> None:
        self._client = AsyncGroq(api_key=settings.groq_api_key)
        self._model = settings.groq_router_model

    async def classify(self, user_message: str, *, system_prompt: str) -> AgentIntent:
        if not user_message.strip():
            return AgentIntent.UNKNOWN

        try:
            completion = await self._client.chat.completions.create(
                model=self._model,
                temperature=0,
                max_tokens=64,
                response_format={"type": "json_object"},
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
            )
        except Exception as exc:
            raise LLMProviderError(f"Groq router failed: {exc}") from exc

        raw = (completion.choices[0].message.content or "").strip()
        try:
            payload = json.loads(raw)
            intent_str = str(payload.get("intent", "unknown")).strip().lower()
        except json.JSONDecodeError as exc:
            logger.warning("router.invalid_json", raw=raw)
            raise LLMProviderError(f"Router returned invalid JSON: {raw}") from exc

        if intent_str not in _INTENTS:
            logger.warning("router.unknown_intent", intent=intent_str)
            return AgentIntent.UNKNOWN

        intent = AgentIntent(intent_str)
        logger.info("router.classified", intent=intent.value)
        return intent

    async def aclose(self) -> None:
        close = getattr(self._client, "close", None)
        if callable(close):
            await close()
