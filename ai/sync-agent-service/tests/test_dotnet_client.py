"""httpx client singleton via deps."""
from __future__ import annotations

import httpx

from app.deps import get_http_client, set_http_client


def test_http_client_singleton():
    client = httpx.AsyncClient()
    set_http_client(client)
    assert get_http_client() is client
