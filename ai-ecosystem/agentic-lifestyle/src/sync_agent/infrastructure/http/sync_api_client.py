"""Async HTTP client for SYNC Gateway → C# microservices."""

from __future__ import annotations

from typing import Any
from uuid import UUID

import httpx
import structlog

from sync_agent.core.config import Settings
from sync_agent.core.exceptions import SyncApiError
from sync_agent.infrastructure.http.api_dtos import (
    ApiEnvelope,
    BiometricProfileApiDto,
    PagedEnvelope,
    PersonalizedRoadmapApiDto,
    ProfileSettingsApiDto,
    RecoveryProfileApiDto,
)
from sync_agent.infrastructure.http.retry_transport import request_with_retry

logger = structlog.get_logger(__name__)


class SyncApiClient:
    """
    Calls authenticated SYNC APIs via the Gateway.
    Python never touches IAM/Roadmap databases directly.
    """

    def __init__(
        self,
        *,
        settings: Settings,
        bearer_token: str | None = None,
        client: httpx.AsyncClient | None = None,
    ) -> None:
        self._settings = settings
        self._bearer_token = bearer_token
        self._owns_client = client is None
        self._client = client or httpx.AsyncClient(
            base_url=settings.gateway_base_url.rstrip("/"),
            timeout=httpx.Timeout(settings.gateway_timeout_sec),
            headers=self._build_headers(bearer_token),
        )

    def _build_headers(self, bearer_token: str | None) -> dict[str, str]:
        headers = {"Accept": "application/json"}
        if bearer_token:
            headers["Authorization"] = f"Bearer {bearer_token}"
        return headers

    def set_bearer_token(self, token: str | None) -> None:
        self._bearer_token = token
        if token:
            self._client.headers["Authorization"] = f"Bearer {token}"
        elif "Authorization" in self._client.headers:
            del self._client.headers["Authorization"]

    async def aclose(self) -> None:
        if self._owns_client:
            await self._client.aclose()

    async def get_biometric_profile(self) -> BiometricProfileApiDto:
        envelope = await self._get_envelope(
            "/api/v1/biometrics",
            BiometricProfileApiDto,
        )
        return envelope

    async def get_profile_settings(self) -> ProfileSettingsApiDto:
        return await self._get_envelope(
            "/api/v1/me/profile-settings",
            ProfileSettingsApiDto,
        )

    async def list_roadmaps(
        self,
        *,
        user_id: UUID | None = None,
        page_number: int = 1,
        page_size: int = 20,
    ) -> list[PersonalizedRoadmapApiDto]:
        params: dict[str, Any] = {"pageNumber": page_number, "pageSize": page_size}
        if user_id:
            params["userId"] = str(user_id)
        raw = await self._request_json("GET", "/api/v1/roadmap/roadmaps", params=params)
        return self._parse_paged_list(raw, PersonalizedRoadmapApiDto)

    async def list_recovery_profiles(
        self,
        *,
        user_id: UUID | None = None,
        page_number: int = 1,
        page_size: int = 20,
    ) -> list[RecoveryProfileApiDto]:
        params: dict[str, Any] = {"pageNumber": page_number, "pageSize": page_size}
        if user_id:
            params["userId"] = str(user_id)
        raw = await self._request_json("GET", "/api/v1/roadmap/recovery-profiles", params=params)
        return self._parse_paged_list(raw, RecoveryProfileApiDto)

    async def _get_envelope(self, path: str, model: type) -> Any:
        raw = await self._request_json("GET", path)
        envelope = ApiEnvelope.model_validate(raw)
        if not envelope.success or envelope.data is None:
            raise SyncApiError(
                envelope.message or f"API returned no data for {path}",
                url=path,
            )
        return model.model_validate(envelope.data)

    @staticmethod
    def _parse_paged_list(raw: dict, item_model: type) -> list:
        envelope = PagedEnvelope.model_validate(raw)
        if not envelope.success:
            raise SyncApiError(envelope.message or "Paged request failed")
        if not envelope.data:
            return []
        if not isinstance(envelope.data, list):
            raise SyncApiError("Paged data is not a list")
        return [item_model.model_validate(item) for item in envelope.data]

    async def _request_json(
        self,
        method: str,
        path: str,
        *,
        params: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        response = await request_with_retry(
            self._client,
            method,
            path,
            max_retries=self._settings.gateway_max_retries,
            backoff_sec=self._settings.gateway_retry_backoff_sec,
            params=params,
        )
        if response.status_code == 401:
            raise SyncApiError("Unauthorized — JWT required", status_code=401, url=path)
        if response.status_code == 404:
            raise SyncApiError("Resource not found", status_code=404, url=path)
        if response.status_code >= 400:
            raise SyncApiError(
                f"HTTP {response.status_code}: {response.text[:200]}",
                status_code=response.status_code,
                url=path,
            )
        try:
            body = response.json()
        except ValueError as exc:
            raise SyncApiError(f"Invalid JSON from {path}") from exc
        if not isinstance(body, dict):
            raise SyncApiError(f"Expected JSON object from {path}")
        return body
