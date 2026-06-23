"""Exercise service client — fetches the catalog (for the indexing pipeline)."""
import httpx

from app.config import settings
from app.services.http import auth_headers, unwrap


async def fetch_catalog(token: str, page_size: int = 500) -> list[dict]:
    """GET /api/v1/exercises?pageSize=... → list of ExerciseCatalogDto dicts."""
    url = f"{settings.exercise_service_url}/api/v1/exercises"
    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.get(
            url,
            headers=auth_headers(token),
            params={"pageNumber": 1, "pageSize": page_size},
        )
    data = unwrap(resp)
    if isinstance(data, list):
        return data
    return []
