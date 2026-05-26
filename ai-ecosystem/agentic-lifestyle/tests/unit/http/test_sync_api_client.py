import httpx
import pytest

from sync_agent.core.config import Settings
from sync_agent.core.exceptions import SyncApiError
from sync_agent.infrastructure.http.sync_api_client import SyncApiClient

_BIOMETRIC_JSON = {
    "success": True,
    "message": "ok",
    "data": {
        "userId": "11111111-1111-1111-1111-111111111111",
        "gender": "Male",
        "dateOfBirth": "1990-01-01",
        "heightCm": 175,
        "currentWeightKg": 70,
        "targetWeightKg": 65,
        "fitnessGoal": "LoseFat",
        "activityLevel": "ModeratelyActive",
        "fitnessExperienceLevel": "Intermediate",
        "workoutLocationPreference": "Gym",
        "baseTDEE": 2000,
        "bmr": 1600,
    },
}


@pytest.mark.asyncio
async def test_get_biometric_retries_then_succeeds() -> None:
    calls = {"n": 0}

    async def handler(request: httpx.Request) -> httpx.Response:
        calls["n"] += 1
        if calls["n"] == 1:
            return httpx.Response(503, request=request)
        return httpx.Response(200, json=_BIOMETRIC_JSON, request=request)

    settings = Settings(
        groq_api_key="x",
        gateway_base_url="http://test",
        gateway_max_retries=2,
        gateway_retry_backoff_sec=0.01,
    )
    transport = httpx.MockTransport(handler)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as http:
        client = SyncApiClient(settings=settings, client=http)
        dto = await client.get_biometric_profile()
        assert dto.base_tdee == 2000
        assert calls["n"] == 2


@pytest.mark.asyncio
async def test_unauthorized_raises() -> None:
    async def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(401, json={"success": False, "message": "unauthorized"}, request=request)

    settings = Settings(groq_api_key="x", gateway_base_url="http://test", gateway_max_retries=0)
    transport = httpx.MockTransport(handler)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as http:
        client = SyncApiClient(settings=settings, client=http)
        with pytest.raises(SyncApiError) as exc:
            await client.get_biometric_profile()
        assert exc.value.status_code == 401
