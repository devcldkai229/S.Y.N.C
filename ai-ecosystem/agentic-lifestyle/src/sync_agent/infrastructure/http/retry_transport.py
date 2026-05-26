"""httpx transport with exponential backoff for transient failures."""

from __future__ import annotations

import asyncio
from collections.abc import Callable
from typing import Any

import httpx
import structlog

logger = structlog.get_logger(__name__)

RETRYABLE_STATUS = {408, 429, 500, 502, 503, 504}


async def request_with_retry(
    client: httpx.AsyncClient,
    method: str,
    url: str,
    *,
    max_retries: int,
    backoff_sec: float,
    retry_on: Callable[[httpx.Response | None, Exception | None], bool] | None = None,
    **kwargs: Any,
) -> httpx.Response:
    last_exc: Exception | None = None
    last_response: httpx.Response | None = None

    for attempt in range(max_retries + 1):
        try:
            response = await client.request(method, url, **kwargs)
            last_response = response
            should_retry = (
                retry_on(response, None)
                if retry_on
                else response.status_code in RETRYABLE_STATUS
            )
            if not should_retry:
                return response
            last_exc = httpx.HTTPStatusError(
                f"Retryable status {response.status_code}",
                request=response.request,
                response=response,
            )
        except (httpx.TimeoutException, httpx.NetworkError) as exc:
            last_exc = exc
            should_retry = retry_on(None, exc) if retry_on else True
            if not should_retry:
                raise

        if attempt >= max_retries:
            break

        delay = backoff_sec * (2**attempt)
        logger.warning(
            "http.retry",
            method=method,
            url=url,
            attempt=attempt + 1,
            delay_sec=delay,
            error=str(last_exc),
            status=getattr(last_response, "status_code", None),
        )
        await asyncio.sleep(delay)

    if last_response is not None and last_exc and isinstance(last_exc, httpx.HTTPStatusError):
        return last_response
    if last_exc:
        raise last_exc
    raise RuntimeError("request_with_retry exhausted without response")
