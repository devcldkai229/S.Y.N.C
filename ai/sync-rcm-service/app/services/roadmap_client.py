"""Roadmap service client — latest recovery profile + recent workout executions."""
import asyncio

import httpx

from app.config import settings
from app.services.http import auth_headers, unwrap


async def fetch_latest_recovery(token: str) -> dict | None:
    url = f"{settings.roadmap_service_url}/api/v1/recovery-profiles"
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(
            url, headers=auth_headers(token), params={"pageNumber": 1, "pageSize": 1}
        )
    data = unwrap(resp)
    if isinstance(data, list) and data:
        return data[0]
    if isinstance(data, dict):
        return data
    return None


async def fetch_recent_executions(token: str, page_size: int = 5) -> list[dict]:
    url = f"{settings.roadmap_service_url}/api/v1/workout-executions"
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(
            url, headers=auth_headers(token), params={"pageNumber": 1, "pageSize": page_size}
        )
    data = unwrap(resp)
    return data if isinstance(data, list) else []


async def fetch_roadmap_bundle(token: str) -> tuple[dict | None, list[dict]]:
    recovery, recent = await asyncio.gather(
        fetch_latest_recovery(token),
        fetch_recent_executions(token),
        return_exceptions=True,
    )
    return (
        recovery if isinstance(recovery, dict) else None,
        recent if isinstance(recent, list) else [],
    )
