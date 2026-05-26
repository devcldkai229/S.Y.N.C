"""Orchestrates parallel JIT HTTP fetches into a single JitContext."""

from __future__ import annotations

import asyncio
from typing import Any
from uuid import UUID

import structlog

from sync_agent.core.exceptions import JitContextFetchError, SyncApiError
from sync_agent.domain.schemas.agent.jit_context import JitContext
from sync_agent.infrastructure.http.mappers import (
    map_biometric_api_to_domain,
    map_preferences_api_to_domain,
    map_recovery_api_to_domain,
    map_roadmap_api_to_domain,
    pick_active_roadmap,
    pick_latest_recovery,
)
from sync_agent.infrastructure.http.sync_api_client import SyncApiClient

__all__ = ["JitContextFetcher"]

logger = structlog.get_logger(__name__)


class JitContextFetcher:
    """
    Fetches live user context from C# APIs (via Gateway).
    Partial failures are tolerated — agent receives whatever is available.
    """

    def __init__(self, api_client: SyncApiClient) -> None:
        self._api = api_client

    async def fetch(
        self,
        *,
        user_id: UUID | None = None,
        include_biometrics: bool = True,
        include_preferences: bool = True,
        include_roadmap: bool = True,
        include_recovery: bool = True,
        raise_on_total_failure: bool = False,
    ) -> JitContext:
        errors: dict[str, str] = {}
        results: dict[str, Any] = {}

        async def _safe(name: str, coro) -> None:
            try:
                results[name] = await coro
            except SyncApiError as exc:
                errors[name] = str(exc)
                logger.warning("jit.fetch.failed", source=name, error=str(exc))
            except Exception as exc:
                errors[name] = f"{type(exc).__name__}: {exc}"
                logger.exception("jit.fetch.unexpected", source=name)

        tasks: list[tuple[str, Any]] = []
        if include_biometrics:
            tasks.append(("biometric", self._api.get_biometric_profile()))
        if include_preferences:
            tasks.append(("preferences", self._api.get_profile_settings()))
        if include_roadmap:
            tasks.append(("roadmap", self._api.list_roadmaps(user_id=user_id)))
        if include_recovery:
            tasks.append(("recovery", self._api.list_recovery_profiles(user_id=user_id)))

        await asyncio.gather(*[_safe(name, coro) for name, coro in tasks])

        context = JitContext(
            biometric_profile=self._map_biometric(results.get("biometric")),
            user_preference=self._map_preferences(results.get("preferences")),
            personalized_roadmap=self._map_roadmap(results.get("roadmap")),
            ai_context_profile=None,  # No public C# endpoint yet
            recovery_profile=self._map_recovery(results.get("recovery")),
        )

        if errors and context.is_empty and raise_on_total_failure:
            raise JitContextFetchError(
                "All JIT context sources failed",
                errors=errors,
            )

        if errors:
            logger.info("jit.fetch.partial", failed=list(errors.keys()), ok=not context.is_empty)

        return context

    @staticmethod
    def _map_biometric(raw: Any) -> Any:
        if raw is None:
            return None
        return map_biometric_api_to_domain(raw)

    @staticmethod
    def _map_preferences(raw: Any) -> Any:
        if raw is None:
            return None
        return map_preferences_api_to_domain(raw.preferences, user_id=raw.user_id)

    @staticmethod
    def _map_roadmap(raw: Any) -> Any:
        if not raw:
            return None
        chosen = pick_active_roadmap(raw)
        return map_roadmap_api_to_domain(chosen) if chosen else None

    @staticmethod
    def _map_recovery(raw: Any) -> Any:
        if not raw:
            return None
        chosen = pick_latest_recovery(raw)
        return map_recovery_api_to_domain(chosen) if chosen else None
