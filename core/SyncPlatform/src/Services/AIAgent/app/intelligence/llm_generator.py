"""Step 4b — call DeepSeek (OpenAI-compatible) and parse the JSON response.

Mirrors the pattern used by the .NET Notification DeepSeekClient: same base URL,
model, json_object response format, and ```-fence cleanup.
"""
import json
from typing import Any

from app.config import settings


class LlmUnavailable(RuntimeError):
    """Raised when no API key is configured or the LLM call fails — callers fall
    back to deterministic top-ranked selection."""


def llm_enabled() -> bool:
    return bool(settings.deepseek_api_key)


def _clean(content: str) -> str:
    text = (content or "").strip()
    if text.startswith("```json"):
        text = text[7:].strip()
    elif text.startswith("```"):
        text = text[3:].strip()
    if text.endswith("```"):
        text = text[:-3].strip()
    return text


async def complete_json(system_prompt: str, user_prompt: str, max_tokens: int = 1200) -> dict[str, Any]:
    if not llm_enabled():
        raise LlmUnavailable("DeepSeek API key not configured")

    from openai import AsyncOpenAI

    client = AsyncOpenAI(api_key=settings.deepseek_api_key, base_url=settings.deepseek_base_url)
    try:
        resp = await client.chat.completions.create(
            model=settings.deepseek_model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.7,
            max_tokens=max_tokens,
            response_format={"type": "json_object"},
        )
    except Exception as exc:  # network / auth / quota
        raise LlmUnavailable(str(exc)) from exc

    raw = resp.choices[0].message.content if resp.choices else ""
    try:
        parsed = json.loads(_clean(raw))
    except json.JSONDecodeError as exc:
        raise LlmUnavailable(f"Bad JSON from LLM: {raw[:200]}") from exc

    tokens = resp.usage.total_tokens if resp.usage else 0
    parsed["_tokens"] = tokens
    return parsed
