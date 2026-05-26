"""OpenAI workers with strict JSON schema (spoken_response + tool_calls)."""

import structlog
from openai import AsyncOpenAI

from sync_agent.core.config import Settings
from sync_agent.core.exceptions import LLMProviderError
from sync_agent.domain.schemas.agent.llm_output import LLMAgentOutput

logger = structlog.get_logger(__name__)


class OpenAIStructuredWorker:
    """
    Uses OpenAI structured outputs (json_schema) so every worker response
    conforms to LLMAgentOutput.
    """

    def __init__(self, *, settings: Settings) -> None:
        self._client = AsyncOpenAI(api_key=settings.openai_api_key)
        self._model = settings.openai_worker_model

    async def generate(
        self,
        *,
        system_prompt: str,
        user_message: str,
    ) -> LLMAgentOutput:
        try:
            completion = await self._client.beta.chat.completions.parse(
                model=self._model,
                temperature=0.3,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                response_format=LLMAgentOutput,
            )
        except Exception as exc:
            raise LLMProviderError(f"OpenAI worker failed: {exc}") from exc

        parsed = completion.choices[0].message.parsed
        if parsed is None:
            refusal = completion.choices[0].message.refusal
            raise LLMProviderError(f"OpenAI refused or empty parse: {refusal}")

        logger.info(
            "openai.worker.complete",
            model=self._model,
            tool_calls=len(parsed.tool_calls),
            spoken_len=len(parsed.spoken_response),
        )
        return parsed

    async def aclose(self) -> None:
        await self._client.close()
