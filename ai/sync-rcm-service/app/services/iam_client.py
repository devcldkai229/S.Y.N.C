"""IAM service client — biometrics + profile settings for the current user."""
import asyncio

import httpx

from app.config import settings
from app.services.http import auth_headers, unwrap


async def fetch_biometrics(token: str) -> dict | None:
    url = f"{settings.iam_service_url}/api/v1/biometrics"
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(url, headers=auth_headers(token))
    data = unwrap(resp)
    return data if isinstance(data, dict) else None


async def fetch_profile_settings(token: str) -> dict | None:
    url = f"{settings.iam_service_url}/api/v1/me/profile-settings"
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(url, headers=auth_headers(token))
    data = unwrap(resp)
    return data if isinstance(data, dict) else None


async def fetch_iam_bundle(token: str) -> tuple[dict | None, dict | None]:
    bio, prefs = await asyncio.gather(
        fetch_biometrics(token),
        fetch_profile_settings(token),
        return_exceptions=True,
    )
    return (
        bio if isinstance(bio, dict) else None,
        prefs if isinstance(prefs, dict) else None,
    )
