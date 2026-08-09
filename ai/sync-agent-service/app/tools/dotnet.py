"""Async adapters gọi .NET microservices qua REST nội bộ.

Nguyên tắc:
- KHÔNG truy cập DB service khác trực tiếp — luôn qua REST (giữ business rule:
  validation, hạn mức chi tiêu, idempotency của Order...).
- Mỗi request gắn header `X-Internal-Api-Key` (xem InternalApiKeyMiddleware bên .NET).
- User scope truyền qua path/body (`userId`), không dùng JWT.
- Có timeout + retry (exponential backoff + jitter); lỗi tool -> trả graceful,
  không làm sập turn hội thoại.
"""
from __future__ import annotations

from typing import Any

import httpx
from tenacity import retry, retry_if_exception, stop_after_attempt, wait_exponential_jitter

from app.config import get_settings

_TIMEOUT = httpx.Timeout(5.0, connect=2.0)
# Batch writes (schedule-week many sessions) can exceed the default 5s.
_WRITE_TIMEOUT = httpx.Timeout(30.0, connect=5.0)
_LIMITS = httpx.Limits(max_keepalive_connections=20, max_connections=50)


class DotnetApiError(httpx.HTTPStatusError):
    """Lỗi HTTP từ .NET kèm message body đọc được.

    Kế thừa HTTPStatusError để các handler hiện có (vd 429 quota) vẫn bắt được,
    nhưng str(exc) là message thật từ .NET thay vì "Client error '400 ...'".
    """

    def __init__(self, message: str, *, request: httpx.Request, response: httpx.Response):
        super().__init__(message, request=request, response=response)
        self.status_code = response.status_code
        self.message = message


def _extract_error_message(resp: httpx.Response) -> str:
    """Bóc message từ body lỗi .NET (ApiResponse / ProblemDetails / validation factory)."""
    try:
        body = resp.json()
    except Exception:
        text = (resp.text or "").strip()
        return text[:300] if text else f"HTTP {resp.status_code}"
    if isinstance(body, dict):
        msg = (
            body.get("message") or body.get("Message")
            or body.get("detail") or body.get("Detail")
            or body.get("title") or body.get("Title")
        )
        errors = body.get("errors") or body.get("Errors")
        parts: list[str] = []
        if msg:
            parts.append(str(msg))
        if isinstance(errors, dict):
            for field, errs in list(errors.items())[:5]:
                if isinstance(errs, list):
                    parts.append(f"{field}: {'; '.join(str(e) for e in errs[:2])}")
                else:
                    parts.append(f"{field}: {errs}")
        if parts:
            return " | ".join(parts)[:500]
    return f"HTTP {resp.status_code}"


def _raise_for_status(r: httpx.Response) -> None:
    if r.status_code < 400:
        return
    raise DotnetApiError(_extract_error_message(r), request=r.request, response=r)


def _is_transient(exc: BaseException) -> bool:
    """Chỉ retry lỗi tạm thời (mạng/timeout/5xx/429). 4xx là lỗi vĩnh viễn —
    retry chỉ tốn 3 lượt gọi và che mất nguyên nhân thật."""
    if isinstance(exc, httpx.HTTPStatusError):
        code = exc.response.status_code
        return code >= 500 or code == 429
    return isinstance(exc, (httpx.TimeoutException, httpx.TransportError))


# reraise=True: hết retry thì ném lại exception gốc (đọc được), KHÔNG bọc RetryError.
_dotnet_retry = retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential_jitter(initial=0.2, max=2.0),
    retry=retry_if_exception(_is_transient),
    reraise=True,
)


def readable_error(exc: BaseException) -> str:
    """Diễn giải exception hạ tầng thành message tiếng Việt cho LLM/user."""
    try:
        from tenacity import RetryError

        if isinstance(exc, RetryError) and exc.last_attempt is not None:
            inner = exc.last_attempt.exception()
            if inner is not None:
                exc = inner
    except Exception:
        pass
    if isinstance(exc, DotnetApiError):
        return f"Lỗi từ hệ thống ({exc.status_code}): {exc.message}"
    if isinstance(exc, httpx.HTTPStatusError):
        return f"Lỗi từ hệ thống ({exc.response.status_code})."
    if isinstance(exc, (httpx.TimeoutException, httpx.TransportError)):
        return "Không kết nối được dịch vụ nội bộ (timeout/mạng). Thử lại sau nhé."
    return str(exc) or type(exc).__name__


def _headers(user_id: str) -> dict[str, str]:
    s = get_settings()
    return {
        "X-Internal-Api-Key": s.internal_api_key,
        "X-User-Id": user_id,
        "Accept": "application/json",
    }


def _http2_enabled() -> bool:
    try:
        import h2  # noqa: F401

        return True
    except ModuleNotFoundError:
        return False


def _client_kwargs() -> dict[str, Any]:
    kw: dict[str, Any] = {"timeout": _TIMEOUT, "limits": _LIMITS}
    if _http2_enabled():
        kw["http2"] = True
    return kw


async def _request(method: str, url: str, user_id: str, **kwargs: Any) -> httpx.Response:
    from app.deps import get_http_client

    client = get_http_client()
    headers = {**_headers(user_id), **kwargs.pop("headers", {})}
    if client is not None:
        return await client.request(method, url, headers=headers, **kwargs)
    async with httpx.AsyncClient(**_client_kwargs()) as ephemeral:
        return await ephemeral.request(method, url, headers=headers, **kwargs)


def _unwrap(body: Any) -> Any:
    """Bóc ApiResponse<T> của .NET: {success, data, message} -> data."""
    if isinstance(body, dict) and "data" in body and ("success" in body or "message" in body):
        return body.get("data")
    return body


def _normalize(data: Any) -> dict[str, Any]:
    if isinstance(data, dict):
        return data
    if isinstance(data, list):
        return {"items": data}
    return {"value": data}


@_dotnet_retry
async def _get(base: str, path: str, user_id: str, **params: Any) -> dict[str, Any]:
    r = await _request("GET", f"{base}{path}", user_id, params=params or None)
    _raise_for_status(r)
    return _normalize(_unwrap(r.json()))


@_dotnet_retry
async def _post(base: str, path: str, user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    r = await _request("POST", f"{base}{path}", user_id, json=payload)
    _raise_for_status(r)
    return _normalize(_unwrap(r.json()))


@_dotnet_retry
async def _post_long(
    base: str, path: str, user_id: str, payload: dict[str, Any],
) -> dict[str, Any]:
    """POST with longer timeout for multi-session writes (schedule-week)."""
    r = await _request(
        "POST", f"{base}{path}", user_id, json=payload, timeout=_WRITE_TIMEOUT,
    )
    _raise_for_status(r)
    return _normalize(_unwrap(r.json()))


@_dotnet_retry
async def _put(base: str, path: str, user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    r = await _request("PUT", f"{base}{path}", user_id, json=payload)
    _raise_for_status(r)
    return _normalize(_unwrap(r.json()))


@_dotnet_retry
async def _patch(base: str, path: str, user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
        r = await client.patch(f"{base}{path}", headers=_headers(user_id), json=payload)
        _raise_for_status(r)
        if r.status_code == 204 or not r.content:
            return {}
        return _normalize(_unwrap(r.json()))


# ----------------------------------------------------------------------------
# IAM — profile / biometrics / AIContextProfile
# ----------------------------------------------------------------------------
async def get_user_snapshot(user_id: str) -> dict[str, Any]:
    """GET /api/internal/ai-context/{userId}/full-context"""
    s = get_settings()
    return await _get(s.iam_base_url, f"/api/internal/ai-context/{user_id}/full-context", user_id)


async def consume_ai_quota(user_id: str) -> dict[str, Any]:
    """POST /api/internal/ai-context/{userId}/consume-ai-quota — monthly quota check/increment."""
    s = get_settings()
    try:
        data = await _post(
            s.iam_base_url,
            f"/api/internal/ai-context/{user_id}/consume-ai-quota",
            user_id,
            {},
        )
        if "allowed" not in data and "Allowed" in data:
            data = {
                "allowed": data.get("Allowed"),
                "used": data.get("Used"),
                "limit": data.get("Limit"),
                "periodKey": data.get("PeriodKey"),
                "subscriptionTier": data.get("SubscriptionTier"),
            }
        return data
    except httpx.HTTPStatusError as exc:
        if exc.response.status_code == 429:
            try:
                body = exc.response.json()
                data = _unwrap(body)
                if isinstance(data, dict):
                    return {
                        "allowed": data.get("allowed", data.get("Allowed", False)),
                        "used": data.get("used", data.get("Used")),
                        "limit": data.get("limit", data.get("Limit")),
                    }
            except Exception:
                pass
            return {"allowed": False}
        raise


async def get_gamification_status(user_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(s.iam_base_url, f"/api/internal/gamification/{user_id}", user_id)


async def suggest_next_achievement(user_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(s.iam_base_url, f"/api/internal/gamification/{user_id}/next-achievement", user_id)


async def patch_ai_context(user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    s = get_settings()
    return await _patch(s.iam_base_url, f"/api/internal/ai-context/{user_id}", user_id, payload)


async def get_nutrition_targets(user_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(s.iam_base_url, f"/api/internal/biometrics/{user_id}/nutrition-targets", user_id)


async def get_community_highlights(user_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(s.social_base_url, "/api/internal/social/highlights", user_id, userId=user_id)


# ----------------------------------------------------------------------------
# Roadmap — lịch tập / điều chỉnh / replan
# ----------------------------------------------------------------------------
async def get_today_workout(user_id: str, *, time_zone_id: str | None = None) -> dict[str, Any]:
    s = get_settings()
    params: dict[str, Any] = {}
    if time_zone_id:
        params["timeZoneId"] = time_zone_id
    return await _get(
        s.roadmap_base_url,
        f"/api/internal/workout-activity/today/{user_id}",
        user_id,
        **params,
    )


async def get_active_roadmap(user_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(
        s.roadmap_base_url,
        f"/api/internal/roadmap/users/{user_id}/active",
        user_id,
    )


async def get_roadmap(user_id: str, roadmap_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(
        s.roadmap_base_url,
        f"/api/internal/roadmap/{roadmap_id}",
        user_id,
    )


async def get_roadmap_sessions(user_id: str, roadmap_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(
        s.roadmap_base_url,
        f"/api/internal/roadmap/{roadmap_id}/sessions",
        user_id,
    )


async def update_roadmap(user_id: str, roadmap_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    s = get_settings()
    return await _patch(
        s.roadmap_base_url,
        f"/api/internal/roadmap/{roadmap_id}",
        user_id,
        payload,
    )


async def schedule_roadmap_session(user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    s = get_settings()
    body = {"userId": user_id, **payload}
    return await _post(
        s.roadmap_base_url,
        "/api/internal/roadmap/sessions/schedule",
        user_id,
        body,
    )


async def get_workout_executions_range(
    user_id: str,
    *,
    from_iso: str | None = None,
    to_iso: str | None = None,
    time_zone_id: str | None = None,
) -> dict[str, Any]:
    s = get_settings()
    params: dict[str, Any] = {}
    if from_iso:
        params["from"] = from_iso
    if to_iso:
        params["to"] = to_iso
    if time_zone_id:
        params["timeZoneId"] = time_zone_id
    return await _get(
        s.roadmap_base_url,
        f"/api/internal/roadmap/workout-executions/{user_id}",
        user_id,
        **params,
    )


async def adjust_intensity(user_id: str, session_id: str, factor: float) -> dict[str, Any]:
    s = get_settings()
    return await _post(
        s.roadmap_base_url,
        f"/api/internal/roadmap/sessions/{session_id}/adjust-intensity",
        user_id,
        {"userId": user_id, "factor": factor},
    )


async def request_replan(user_id: str, reason: str) -> dict[str, Any]:
    """Tác vụ nặng — queue ticket; worker xử lý async."""
    s = get_settings()
    return await _post(
        s.roadmap_base_url,
        "/api/internal/roadmap/replan",
        user_id,
        {"userId": user_id, "reason": reason},
    )


async def create_roadmap(user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    """POST /api/internal/roadmap — tạo PersonalizedRoadmap mới."""
    s = get_settings()
    return await _post(
        s.roadmap_base_url,
        "/api/internal/roadmap",
        user_id,
        {"userId": user_id, **payload},
    )


async def delete_roadmap(user_id: str, roadmap_id: str) -> dict[str, Any]:
    """DELETE /api/internal/roadmap/{roadmapId} — xoá roadmap kèm cascade sessions."""
    from app.deps import get_http_client
    s = get_settings()
    url = f"{s.roadmap_base_url}/api/internal/roadmap/{roadmap_id}"
    client = get_http_client()
    if client is not None:
        r = await client.delete(url, headers=_headers(user_id))
    else:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as c:
            r = await c.delete(url, headers=_headers(user_id))
    r.raise_for_status()
    return _normalize(_unwrap(r.json()))


async def get_sessions_by_range(
    user_id: str,
    *,
    from_iso: str | None = None,
    to_iso: str | None = None,
    time_zone_id: str | None = None,
) -> dict[str, Any]:
    """GET /api/internal/roadmap/users/{userId}/sessions?from=&to=&timeZoneId=."""
    s = get_settings()
    params: dict[str, Any] = {}
    if from_iso:
        params["from"] = from_iso
    if to_iso:
        params["to"] = to_iso
    if time_zone_id:
        params["timeZoneId"] = time_zone_id
    return await _get(
        s.roadmap_base_url,
        f"/api/internal/roadmap/users/{user_id}/sessions",
        user_id,
        **params,
    )


async def schedule_week(user_id: str, sessions: list[dict[str, Any]]) -> dict[str, Any]:
    """POST /api/internal/roadmap/sessions/schedule-week — lên lịch 1 tuần cùng lúc."""
    s = get_settings()
    for sess in sessions:
        sess.setdefault("userId", user_id)
    return await _post_long(
        s.roadmap_base_url,
        "/api/internal/roadmap/sessions/schedule-week",
        user_id,
        {"sessions": sessions},
    )


# ── Adaptive Coaching Engine (IAM) ───────────────────────────────────────────
async def log_weigh_in(
    user_id: str,
    *,
    weight_kg: float,
    body_fat_percentage: float | None = None,
    note: str | None = None,
    source: str = "Manual",
) -> dict[str, Any]:
    """POST /api/internal/biometrics/{userId}/weigh-in — ghi BiometricHistory."""
    s = get_settings()
    payload: dict[str, Any] = {"weightKg": weight_kg, "source": source}
    if body_fat_percentage is not None:
        payload["bodyFatPercentage"] = body_fat_percentage
    if note:
        payload["note"] = note
    return await _post(
        s.iam_base_url, f"/api/internal/biometrics/{user_id}/weigh-in", user_id, payload,
    )


async def get_weight_history(
    user_id: str,
    *,
    from_iso: str,
    to_iso: str,
) -> dict[str, Any]:
    """GET /api/internal/biometrics/{userId}/weight-history"""
    s = get_settings()
    return await _get(
        s.iam_base_url,
        f"/api/internal/biometrics/{user_id}/weight-history",
        user_id,
        **{"from": from_iso, "to": to_iso},
    )


async def apply_adaptive_targets(user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    """POST /api/internal/biometrics/{userId}/apply-targets — áp targets + audit log."""
    s = get_settings()
    return await _post(
        s.iam_base_url, f"/api/internal/biometrics/{user_id}/apply-targets", user_id, payload,
    )


async def create_level_snapshot(user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    """POST /api/internal/biometrics/{userId}/level-snapshots"""
    s = get_settings()
    return await _post(
        s.iam_base_url, f"/api/internal/biometrics/{user_id}/level-snapshots", user_id, payload,
    )


async def get_latest_level_snapshot(user_id: str) -> dict[str, Any]:
    """GET /api/internal/biometrics/{userId}/level-snapshots/latest"""
    s = get_settings()
    return await _get(
        s.iam_base_url, f"/api/internal/biometrics/{user_id}/level-snapshots/latest", user_id,
    )


async def apply_training_adjustment(user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    """POST /api/internal/roadmap/users/{userId}/apply-training-adjustment"""
    s = get_settings()
    return await _post(
        s.roadmap_base_url,
        f"/api/internal/roadmap/users/{user_id}/apply-training-adjustment",
        user_id,
        payload,
    )


async def sync_roadmap_body_metrics(
    user_id: str,
    *,
    current_weight_kg: float | None = None,
    target_weight_kg: float | None = None,
    initial_fat_percentage: float | None = None,
    target_fat_percentage: float | None = None,
    current_phase: str | None = None,
) -> dict[str, Any]:
    """PATCH /api/internal/roadmap/users/{userId}/body-metrics — mirror cân/mỡ lên active roadmap."""
    s = get_settings()
    payload: dict[str, Any] = {}
    if current_weight_kg is not None:
        payload["currentWeightKg"] = current_weight_kg
    if target_weight_kg is not None:
        payload["targetWeightKg"] = target_weight_kg
    if initial_fat_percentage is not None:
        payload["initialFatPercentage"] = initial_fat_percentage
    if target_fat_percentage is not None:
        payload["targetFatPercentage"] = target_fat_percentage
    if current_phase:
        payload["currentPhase"] = current_phase
    if not payload:
        return {}
    return await _patch(
        s.roadmap_base_url,
        f"/api/internal/roadmap/users/{user_id}/body-metrics",
        user_id,
        payload,
    )


async def get_roadmap_session(user_id: str, session_id: str) -> dict[str, Any]:
    """GET /api/internal/roadmap/sessions/{sessionId} — đọc 1 session (validate đổi lịch)."""
    s = get_settings()
    return await _get(
        s.roadmap_base_url,
        f"/api/internal/roadmap/sessions/{session_id}",
        user_id,
    )


async def reschedule_session(
    user_id: str,
    session_id: str,
    new_date: str,
    new_time: str = "07:00",
) -> dict[str, Any]:
    """POST /api/internal/roadmap/sessions/{sessionId}/reschedule — đổi ngày/giờ session."""
    s = get_settings()
    return await _post(
        s.roadmap_base_url,
        f"/api/internal/roadmap/sessions/{session_id}/reschedule",
        user_id,
        {"userId": user_id, "newDate": new_date, "newTime": new_time},
    )


async def update_roadmap_session(
    user_id: str,
    session_id: str,
    payload: dict[str, Any],
) -> dict[str, Any]:
    """PUT /api/internal/roadmap/sessions/{sessionId} — thay title/blocks/duration."""
    s = get_settings()
    return await _put(
        s.roadmap_base_url,
        f"/api/internal/roadmap/sessions/{session_id}",
        user_id,
        payload,
    )


async def delete_roadmap_session(user_id: str, session_id: str) -> dict[str, Any]:
    """DELETE /api/internal/roadmap/sessions/{sessionId}."""
    from app.deps import get_http_client
    s = get_settings()
    url = f"{s.roadmap_base_url}/api/internal/roadmap/sessions/{session_id}"
    client = get_http_client()
    if client is not None:
        r = await client.delete(url, headers=_headers(user_id))
    else:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as c:
            r = await c.delete(url, headers=_headers(user_id))
    r.raise_for_status()
    return _normalize(_unwrap(r.json()))


async def get_workout_history(
    user_id: str,
    *,
    from_iso: str | None = None,
    to_iso: str | None = None,
    time_zone_id: str | None = None,
) -> dict[str, Any]:
    """GET workout-executions trong khoảng ngày (alias tên thân thiện với AI)."""
    return await get_workout_executions_range(
        user_id, from_iso=from_iso, to_iso=to_iso, time_zone_id=time_zone_id,
    )


async def search_exercises(
    user_id: str,
    *,
    query: str = "",
    muscle: str = "",
    equipment: str = "",
    difficulty: str = "",
    limit: int = 5,
) -> dict[str, Any]:
    s = get_settings()
    params: dict[str, Any] = {"limit": limit}
    if query:
        params["query"] = query
    if muscle:
        params["muscle"] = muscle
    if equipment:
        params["equipment"] = equipment
    if difficulty:
        params["difficulty"] = difficulty
    return await _get(s.exercise_base_url, "/api/internal/exercises", user_id, **params)


async def get_exercise_detail(user_id: str, exercise_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(s.exercise_base_url, f"/api/internal/exercises/{exercise_id}/detail", user_id)


async def lookup_exercise_detail(
    user_id: str,
    *,
    query: str = "",
    slug: str = "",
) -> dict[str, Any]:
    """GET /api/internal/exercises/lookup/detail?query=&slug= — resolve name/slug → detail."""
    s = get_settings()
    params: dict[str, Any] = {}
    if query:
        params["query"] = query
    if slug:
        params["slug"] = slug
    try:
        return await _get(
            s.exercise_base_url,
            "/api/internal/exercises/lookup/detail",
            user_id,
            **params,
        )
    except httpx.HTTPStatusError as exc:
        if exc.response.status_code not in (404, 405):
            raise
    # Fallback when lookup endpoint unavailable: search → detail by id
    search_query = slug or query
    if not search_query:
        return {"error": "query or slug is required"}
    search = await search_exercises(user_id, query=search_query, limit=1)
    items = search.get("items") or []
    if not items:
        return {"error": f"Không tìm thấy bài tập: {search_query}"}
    exercise_id = items[0].get("id")
    if not exercise_id:
        return {"error": f"Không có id cho bài tập: {search_query}"}
    return await get_exercise_detail(user_id, str(exercise_id))


async def get_exercise_media(user_id: str, exercise_id: str, asset_type: str = "") -> dict[str, Any]:
    s = get_settings()
    params = {"assetType": asset_type} if asset_type else {}
    return await _get(
        s.exercise_base_url,
        f"/api/internal/exercises/{exercise_id}/media",
        user_id,
        **params,
    )


async def substitute_exercise(
    user_id: str,
    session_id: str,
    exercise_id: str,
    reason: str = "",
    *,
    replace_exercise_id: str = "",
    exercise_name: str = "",
) -> dict[str, Any]:
    s = get_settings()
    body: dict[str, Any] = {
        "userId": user_id,
        "exerciseId": exercise_id,
        "reason": reason,
    }
    if replace_exercise_id:
        body["replaceExerciseId"] = replace_exercise_id
    if exercise_name:
        body["exerciseName"] = exercise_name
    return await _post(
        s.roadmap_base_url,
        f"/api/internal/roadmap/sessions/{session_id}/substitute",
        user_id,
        body,
    )


async def log_workout_execution(user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    s = get_settings()
    return await _post(
        s.roadmap_base_url,
        "/api/internal/roadmap/workout-executions",
        user_id,
        {"userId": user_id, **payload},
    )


async def log_set(user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    s = get_settings()
    return await _post(
        s.roadmap_base_url,
        "/api/internal/roadmap/exercise-set-logs",
        user_id,
        {"userId": user_id, **payload},
    )


async def get_recovery_status(user_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(s.roadmap_base_url, f"/api/internal/roadmap/recovery/{user_id}", user_id)


async def get_workout_timeseries(
    user_id: str,
    *,
    from_date: str,
    to_date: str,
    granularity: str = "week",
    time_zone_id: str | None = None,
) -> dict[str, Any]:
    """GET /api/internal/roadmap/{userId}/timeseries"""
    s = get_settings()
    params: dict[str, Any] = {
        "from": from_date,
        "to": to_date,
        "granularity": granularity,
    }
    if time_zone_id:
        params["timeZoneId"] = time_zone_id
    try:
        return await _get(
            s.roadmap_base_url,
            f"/api/internal/roadmap/{user_id}/timeseries",
            user_id,
            **params,
        )
    except Exception as exc:
        return {"error": str(exc), "buckets": []}


async def get_strength_progression(
    user_id: str,
    *,
    exercise_id: str,
    from_date: str | None = None,
    to_date: str | None = None,
    time_zone_id: str | None = None,
) -> dict[str, Any]:
    """GET /api/internal/roadmap/{userId}/strength-progression"""
    s = get_settings()
    params: dict[str, Any] = {"exerciseId": exercise_id}
    if from_date:
        params["from"] = from_date
    if to_date:
        params["to"] = to_date
    if time_zone_id:
        params["timeZoneId"] = time_zone_id
    try:
        return await _get(
            s.roadmap_base_url,
            f"/api/internal/roadmap/{user_id}/strength-progression",
            user_id,
            **params,
        )
    except Exception as exc:
        return {"error": str(exc), "points": []}


# ----------------------------------------------------------------------------
# Nutrition — macro / log meal
# ----------------------------------------------------------------------------
async def get_daily_summary(
    user_id: str,
    *,
    date: str | None = None,
    time_zone_id: str | None = None,
) -> dict[str, Any]:
    s = get_settings()
    params: dict[str, Any] = {}
    if date:
        params["date"] = date
    if time_zone_id:
        params["timeZoneId"] = time_zone_id
    return await _get(
        s.nutrition_base_url,
        f"/api/internal/nutrition/daily-summary/{user_id}",
        user_id,
        **params,
    )


async def get_nutrition_timeseries(
    user_id: str,
    *,
    from_date: str,
    to_date: str,
    granularity: str = "day",
    time_zone_id: str | None = None,
) -> dict[str, Any]:
    """GET /api/internal/nutrition/{userId}/timeseries"""
    s = get_settings()
    params: dict[str, Any] = {
        "from": from_date,
        "to": to_date,
        "granularity": granularity,
    }
    if time_zone_id:
        params["timeZoneId"] = time_zone_id
    try:
        return await _get(
            s.nutrition_base_url,
            f"/api/internal/nutrition/{user_id}/timeseries",
            user_id,
            **params,
        )
    except Exception as exc:
        return {"error": str(exc), "buckets": []}


async def log_meal(user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    s = get_settings()
    return await _post(
        s.nutrition_base_url,
        "/api/internal/nutrition/meal-logs",
        user_id,
        {"userId": user_id, **payload},
    )


async def search_food(user_id: str, *, query: str = "", limit: int = 10) -> dict[str, Any]:
    s = get_settings()
    return await _get(
        s.nutrition_base_url,
        "/api/internal/nutrition/food-items",
        user_id,
        query=query,
        limit=limit,
    )


async def get_food_by_barcode(user_id: str, barcode: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(
        s.nutrition_base_url,
        f"/api/internal/nutrition/food-items/barcode/{barcode}",
        user_id,
    )


async def log_water(user_id: str, amount_ml: int) -> dict[str, Any]:
    s = get_settings()
    return await _post(
        s.nutrition_base_url,
        "/api/internal/nutrition/water-intake",
        user_id,
        {"userId": user_id, "milliliters": amount_ml},
    )


# ----------------------------------------------------------------------------
# Marketplace / Order / Payment — commerce
# ----------------------------------------------------------------------------
async def recommend_partner_meals(user_id: str, *, goal: str, max_price: float) -> dict[str, Any]:
    s = get_settings()
    return await _get(
        s.marketplace_base_url,
        "/api/internal/marketplace/recommendations",
        user_id,
        userId=user_id,
        goal=goal,
        maxPrice=max_price,
    )


async def search_partners(
    user_id: str,
    *,
    lat: float | None = None,
    lng: float | None = None,
    partner_type: str = "",
    query: str = "",
    dish: str = "",
    min_rating: float | None = None,
    radius_km: float | None = None,
    limit: int = 10,
) -> dict[str, Any]:
    s = get_settings()
    params: dict[str, Any] = {"limit": max(1, min(int(limit), 30))}
    if lat is not None:
        params["lat"] = lat
    if lng is not None:
        params["lng"] = lng
    if partner_type:
        params["type"] = partner_type
    if query:
        params["query"] = query
    if dish:
        params["dish"] = dish
    if min_rating is not None:
        params["minRating"] = min_rating
    if radius_km is not None:
        params["radiusKm"] = radius_km
    elif lat is not None and lng is not None:
        params["radiusKm"] = 5
    return await _get(s.marketplace_base_url, "/api/internal/partners", user_id, **params)


async def search_nearby_partners(
    user_id: str,
    *,
    lat: float,
    lng: float,
    query: str = "",
    dish: str = "",
    min_rating: float | None = None,
    radius_km: float = 5,
    limit: int = 10,
) -> dict[str, Any]:
    return await search_partners(
        user_id,
        lat=lat,
        lng=lng,
        query=query,
        dish=dish,
        min_rating=min_rating,
        radius_km=radius_km,
        limit=limit,
    )


async def get_partner_detail(
    user_id: str,
    partner_id: str,
    *,
    lat: float | None = None,
    lng: float | None = None,
) -> dict[str, Any]:
    s = get_settings()
    params: dict[str, Any] = {}
    if lat is not None:
        params["lat"] = lat
    if lng is not None:
        params["lng"] = lng
    return await _get(
        s.marketplace_base_url,
        f"/api/internal/partners/{partner_id}/detail",
        user_id,
        **params,
    )


async def get_food_detail(user_id: str, food_menu_item_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(
        s.marketplace_base_url,
        f"/api/internal/food-menu/item/{food_menu_item_id}",
        user_id,
    )


async def get_partner_reviews(
    user_id: str,
    partner_id: str,
    *,
    limit: int = 20,
    page_number: int = 1,
) -> dict[str, Any]:
    s = get_settings()
    return await _get(
        s.marketplace_base_url,
        "/api/internal/reviews",
        user_id,
        targetType="Partner",
        targetId=partner_id,
        limit=max(1, min(int(limit), 50)),
        pageNumber=max(1, int(page_number)),
    )


async def get_food_reviews(
    user_id: str,
    food_menu_item_id: str,
    *,
    limit: int = 20,
    page_number: int = 1,
) -> dict[str, Any]:
    s = get_settings()
    return await _get(
        s.marketplace_base_url,
        "/api/internal/reviews",
        user_id,
        targetType="FoodMenuItem",
        targetId=food_menu_item_id,
        limit=max(1, min(int(limit), 50)),
        pageNumber=max(1, int(page_number)),
    )


async def get_menu(user_id: str, partner_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(s.marketplace_base_url, f"/api/internal/food-menu/{partner_id}", user_id)


async def search_partner_dishes(
    user_id: str,
    *,
    query: str = "",
    partner_id: str = "",
    lat: float | None = None,
    lng: float | None = None,
    radius_km: float | None = None,
    min_rating: float | None = None,
    limit: int = 20,
) -> dict[str, Any]:
    s = get_settings()
    params: dict[str, Any] = {"limit": max(1, min(int(limit), 50))}
    if query:
        params["query"] = query
    if partner_id:
        params["partnerId"] = partner_id
    if lat is not None:
        params["lat"] = lat
    if lng is not None:
        params["lng"] = lng
    if radius_km is not None:
        params["radiusKm"] = radius_km
    if min_rating is not None:
        params["minRating"] = min_rating
    return await _get(
        s.marketplace_base_url,
        "/api/internal/food-menu/search",
        user_id,
        **params,
    )


async def create_premium_payment_link(
    user_id: str,
    *,
    plan_code: str = "Premium",
    billing_cycle: int = 0,
) -> dict[str, Any]:
    """POST /api/internal/payments/subscription/create-link — VietQR Premium upgrade."""
    s = get_settings()
    return await _post(
        s.payment_base_url,
        "/api/internal/payments/subscription/create-link",
        user_id,
        {
            "userId": user_id,
            "planCode": plan_code or "Premium",
            "billingCycle": int(billing_cycle),
        },
    )


async def recommend_affiliate_products(user_id: str, category: str = "") -> dict[str, Any]:
    s = get_settings()
    params = {"category": category} if category else {}
    return await _get(
        s.marketplace_base_url,
        "/api/internal/marketplace/affiliate",
        user_id,
        **params,
    )


async def check_wallet(user_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(s.payment_base_url, f"/api/internal/wallet/{user_id}/balance", user_id)


async def list_vouchers(user_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(s.payment_base_url, f"/api/internal/vouchers/{user_id}", user_id)


async def apply_voucher(user_id: str, order_draft_id: str, voucher_code: str) -> dict[str, Any]:
    s = get_settings()
    return await _post(
        s.payment_base_url,
        "/api/internal/vouchers/apply",
        user_id,
        {"userId": user_id, "orderDraftId": order_draft_id, "voucherCode": voucher_code},
    )


async def topup_wallet(user_id: str, amount: float, method: str) -> dict[str, Any]:
    s = get_settings()
    return await _post(
        s.payment_base_url,
        "/api/internal/wallet/topup",
        user_id,
        {"userId": user_id, "amount": amount, "method": method},
    )


async def get_default_contact(user_id: str) -> dict[str, Any]:
    """IAM fullName/phone + Order saved delivery address."""
    snapshot = await get_user_snapshot(user_id)
    s = get_settings()
    address_raw: dict[str, Any] = {}
    try:
        address_raw = await _get(
            s.order_base_url,
            f"/api/internal/orders/users/{user_id}/delivery-address",
            user_id,
        )
    except Exception as exc:  # pragma: no cover
        address_raw = {"error": str(exc)}

    full_name = (snapshot.get("fullName") or snapshot.get("FullName") or "") if isinstance(snapshot, dict) else ""
    phone = (snapshot.get("phoneNumber") or snapshot.get("PhoneNumber") or "") if isinstance(snapshot, dict) else ""
    address = ""
    lat = lng = None
    if isinstance(address_raw, dict) and not address_raw.get("error"):
        address = address_raw.get("label") or address_raw.get("Label") or ""
        lat = address_raw.get("lat", address_raw.get("Lat"))
        lng = address_raw.get("lng", address_raw.get("Lng"))

    missing: list[str] = []
    if not str(phone).strip():
        missing.append("phone")
    if not str(address).strip():
        missing.append("address")

    return {
        "fullName": str(full_name).strip() or None,
        "phone": str(phone).strip() or None,
        "address": str(address).strip() or None,
        "lat": lat,
        "lng": lng,
        "missingFields": missing,
    }


async def validate_order_items(
    user_id: str,
    *,
    partner_id: str,
    food_menu_item_ids: list[str],
) -> dict[str, Any]:
    s = get_settings()
    return await _post(
        s.marketplace_base_url,
        "/api/internal/food-menu/validate-order",
        user_id,
        {"partnerId": partner_id, "foodMenuItemIds": food_menu_item_ids},
    )


async def quote_order(
    user_id: str,
    *,
    partner_id: str,
    items: list[dict[str, Any]],
    voucher_code: str = "",
) -> dict[str, Any]:
    s = get_settings()
    body: dict[str, Any] = {
        "userId": user_id,
        "partnerId": partner_id,
        "items": items,
    }
    if voucher_code:
        body["voucherCode"] = voucher_code
    return await _post(s.order_base_url, "/api/internal/orders/quote", user_id, body)


async def create_order(user_id: str, payload: dict[str, Any], idempotency_key: str) -> dict[str, Any]:
    """Đặt hàng — bắt buộc idempotency (Order.OrderIdempotencyKey)."""
    s = get_settings()
    body = {
        "userId": user_id,
        **payload,
        "clientRequestKey": idempotency_key,
        "idempotencyKey": idempotency_key,
        "isAiInitiated": True,
    }
    return await _post(s.order_base_url, "/api/internal/orders", user_id, body)


async def get_order(user_id: str, order_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(
        s.order_base_url,
        f"/api/internal/orders/{order_id}",
        user_id,
        userId=user_id,
    )


async def confirm_order_payment(user_id: str, order_id: str, transaction_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _post(
        s.order_base_url,
        f"/api/internal/orders/{order_id}/confirm-payment",
        user_id,
        {"transactionId": transaction_id},
    )


async def charge_order_wallet(
    user_id: str,
    *,
    order_id: str,
    amount: float,
) -> dict[str, Any]:
    s = get_settings()
    return await _post(
        s.payment_base_url,
        "/api/internal/order-payments/charge-wallet",
        user_id,
        {
            "userId": user_id,
            "orderId": order_id,
            "amount": amount,
            "currency": "VND",
            "isAiInitiated": True,
        },
    )


async def create_vietqr_payment(
    user_id: str,
    *,
    order_id: str,
    order_code: str,
    amount: float,
) -> dict[str, Any]:
    s = get_settings()
    return await _post(
        s.payment_base_url,
        "/api/internal/order-payments/vietqr/create",
        user_id,
        {
            "userId": user_id,
            "orderId": order_id,
            "orderCode": order_code,
            "amount": amount,
            "currency": "VND",
        },
    )


async def get_payment_status(
    user_id: str,
    *,
    order_id: str = "",
    payos_order_code: int | None = None,
) -> dict[str, Any]:
    s = get_settings()
    params: dict[str, Any] = {}
    if order_id:
        params["orderId"] = order_id
    if payos_order_code is not None:
        params["payOsOrderCode"] = payos_order_code
    return await _get(
        s.payment_base_url,
        "/api/internal/order-payments/status",
        user_id,
        **params,
    )


async def track_order(user_id: str, order_id: str) -> dict[str, Any]:
    s = get_settings()
    return await _get(
        s.order_base_url,
        f"/api/internal/orders/{order_id}/tracking",
        user_id,
        userId=user_id,
    )


async def reorder(
    user_id: str,
    previous_order_id: str,
    idempotency_key: str,
    *,
    ai_reasoning_snapshot_json: str | None = None,
) -> dict[str, Any]:
    s = get_settings()
    body: dict[str, Any] = {
        "userId": user_id,
        "previousOrderId": previous_order_id,
        "idempotencyKey": idempotency_key,
        "isAiInitiated": True,
    }
    if ai_reasoning_snapshot_json:
        body["aIReasoningSnapshotJson"] = ai_reasoning_snapshot_json
    return await _post(s.order_base_url, "/api/internal/orders/reorder", user_id, body)


# ----------------------------------------------------------------------------
# Notification — can thiệp chủ động
# ----------------------------------------------------------------------------
async def send_notification(user_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    s = get_settings()
    body = {"userId": user_id, **payload}
    return await _post(s.notification_base_url, "/api/internal/notifications/send", user_id, body)
