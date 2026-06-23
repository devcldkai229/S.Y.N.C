"""Shared helpers for calling downstream .NET services (forwarding the user JWT)
and unwrapping the ApiResponse<T> envelope.
"""
from typing import Any

import httpx


def auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}", "Accept": "application/json"}


def unwrap(resp: httpx.Response) -> Any:
    """Return the `data` field of an ApiResponse envelope, or None on failure."""
    if resp.status_code >= 400:
        return None
    try:
        body = resp.json()
    except Exception:
        return None
    if isinstance(body, dict):
        if body.get("success") is False:
            return None
        return body.get("data")
    return body
