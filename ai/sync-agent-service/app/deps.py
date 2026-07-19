"""Shared runtime dependencies — inject từ FastAPI lifespan."""
from __future__ import annotations

from typing import Any

_redis: Any = None
_http_client: Any = None
_pg_pool: Any = None
_fitness_kb: Any = None
_background_tasks: set[Any] = set()


def set_redis(client: Any) -> None:
    global _redis
    _redis = client


def get_redis() -> Any:
    return _redis


def set_http_client(client: Any) -> None:
    global _http_client
    _http_client = client


def get_http_client() -> Any:
    return _http_client


def set_pg_pool(pool: Any) -> None:
    global _pg_pool
    _pg_pool = pool


def get_pg_pool() -> Any:
    return _pg_pool


def set_fitness_kb(kb: Any) -> None:
    global _fitness_kb
    _fitness_kb = kb


def get_fitness_kb() -> Any:
    return _fitness_kb


def track_background_task(task: Any) -> None:
    _background_tasks.add(task)
    task.add_done_callback(_background_tasks.discard)
