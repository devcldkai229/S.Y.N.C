"""Unit tests for Redis pending confirm store + exercise lookup helpers."""
from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest

from app.deps import set_redis
from app.tools.local import _exercise_lookup_queries, resolve_exercise_ids, _ZERO_GUID


def test_exercise_lookup_queries_strips_noise():
    qs = _exercise_lookup_queries("Barbell Bench Press (flat) 3x10")
    assert "Barbell Bench Press (flat) 3x10" in qs
    assert any("Barbell Bench Press" in q for q in qs)
    assert any(q == "Barbell" or q.lower() == "barbell" for q in qs)
    assert any(q.lower() == "bench" for q in qs)


def test_exercise_lookup_queries_empty():
    assert _exercise_lookup_queries("") == []
    assert _exercise_lookup_queries("  ") == []


@pytest.mark.asyncio
async def test_resolve_falls_back_to_token():
    sessions = [{
        "date": "2026-07-12",
        "time": "19:30",
        "sessionTitle": "Legs",
        "sessionType": "Strength",
        "executionBlocks": [
            {
                "order": 1,
                "exerciseId": _ZERO_GUID,
                "exerciseName": "Goblet Squats (warm-up) 3x12",
                "targetSets": 3,
                "targetReps": 12,
            },
        ],
    }]

    async def fake_search(user_id, **kwargs):
        q = (kwargs.get("query") or "").lower()
        if "squat" in q:
            return {
                "items": [{
                    "id": "22222222-2222-2222-2222-222222222222",
                    "nameEn": "Squat",
                }],
            }
        return {"items": []}

    with pytest.MonkeyPatch.context() as mp:
        mp.setattr(
            "app.tools.local.dotnet.search_exercises",
            AsyncMock(side_effect=fake_search),
        )
        out = await resolve_exercise_ids("user-1", sessions)

    assert out
    assert out[0]["executionBlocks"][0]["exerciseId"] == "22222222-2222-2222-2222-222222222222"
    assert resolve_exercise_ids.last_unresolved == []


@pytest.mark.asyncio
async def test_resolve_tracks_unresolved_names():
    sessions = [{
        "executionBlocks": [
            {"exerciseId": "", "exerciseName": "Totally Fake Move XYZ"},
        ],
    }]

    with pytest.MonkeyPatch.context() as mp:
        mp.setattr(
            "app.tools.local.dotnet.search_exercises",
            AsyncMock(return_value={"items": []}),
        )
        out = await resolve_exercise_ids("user-1", sessions)

    assert out == []
    assert "Totally Fake Move XYZ" in resolve_exercise_ids.last_unresolved


@pytest.mark.asyncio
async def test_pending_store_save_get_delete():
    from app import pending_store

    store: dict[str, bytes] = {}

    class FakeRedis:
        async def set(self, key, value, ex=None):
            store[key] = value if isinstance(value, bytes) else value.encode()

        async def get(self, key):
            return store.get(key)

        async def delete(self, key):
            store.pop(key, None)

    set_redis(FakeRedis())
    action = {
        "action_id": "a1",
        "type": "plan_or_edit_workout",
        "staged_plan": {"mode": "create", "sessions": []},
    }
    await pending_store.save_pending("u1", "s1", action)
    got = await pending_store.get_pending("u1", "s1", "a1")
    assert got is not None
    assert got["action_id"] == "a1"
    assert got["type"] == "plan_or_edit_workout"
    await pending_store.delete_pending("u1", "s1", "a1")
    assert await pending_store.get_pending("u1", "s1", "a1") is None
    set_redis(None)


@pytest.mark.asyncio
async def test_schedule_week_uses_long_timeout():
    from app.tools import dotnet as dn

    called: dict = {}

    async def fake_post_long(base, path, user_id, payload):
        called["path"] = path
        return {"items": []}

    with pytest.MonkeyPatch.context() as mp:
        mp.setattr(dn, "_post_long", AsyncMock(side_effect=fake_post_long))
        await dn.schedule_week("u1", [{"sessionTitle": "A"}])
    assert called["path"] == "/api/internal/roadmap/sessions/schedule-week"
