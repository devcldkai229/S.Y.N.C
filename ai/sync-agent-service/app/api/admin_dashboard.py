"""Admin dashboard analytics — đọc ai_turn_audit."""
from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from app.api.security import AuthContext, require_auth
from app.deps import get_pg_pool

router = APIRouter(prefix="/admin/dashboard", tags=["admin-dashboard"])

VN_OFFSET = timedelta(hours=7)
ADMIN_ROLES = frozenset({"SystemAdmin", "Admin", "Staff"})


class DailyPoint(BaseModel):
    date: str
    value: float = 0


class NamedCount(BaseModel):
    name: str
    count: int = 0


class KpiMetric(BaseModel):
    value: float = 0
    previous_value: float | None = None
    delta_percent: float | None = None
    sparkline: list[DailyPoint] = Field(default_factory=list)


class AiDashboardOverview(BaseModel):
    generated_at: str
    days: int
    total_turns: KpiMetric = Field(default_factory=KpiMetric)
    estimated_cost_usd: KpiMetric = Field(default_factory=KpiMetric)
    ai_turns_daily: list[DailyPoint] = Field(default_factory=list)
    intent_distribution: list[NamedCount] = Field(default_factory=list)
    model_tier_distribution: list[NamedCount] = Field(default_factory=list)
    avg_cost_daily: list[DailyPoint] = Field(default_factory=list)


def _require_admin(auth: AuthContext = Depends(require_auth)) -> AuthContext:
    role = auth.role
    if role not in ADMIN_ROLES:
        raise HTTPException(status_code=403, detail="Admin access required")
    return auth


def _vn_date(dt: datetime) -> date:
    return (dt.astimezone(timezone.utc) + VN_OFFSET).date()


def _delta_pct(current: float, previous: float) -> float | None:
    if previous == 0:
        return 100.0 if current > 0 else 0.0
    return round((current - previous) / previous * 100, 1)


@router.get("/overview", response_model=AiDashboardOverview)
async def get_overview(
    days: int = Query(default=30, ge=1, le=365),
    _auth: AuthContext = Depends(_require_admin),
) -> AiDashboardOverview:
    pool = get_pg_pool()
    now = datetime.now(timezone.utc)
    period_start = now - timedelta(days=days)
    previous_start = now - timedelta(days=days * 2)

    if pool is None:
        return AiDashboardOverview(
            generated_at=now.isoformat(),
            days=days,
        )

    rows = await pool.fetch(
        """
        SELECT created_at, intent, tier, estimated_cost_usd
        FROM ai_turn_audit
        WHERE created_at >= $1
        ORDER BY created_at ASC
        """,
        previous_start,
    )

    current_rows = [r for r in rows if r["created_at"] >= period_start]
    previous_rows = [r for r in rows if previous_start <= r["created_at"] < period_start]

    chart_start = _vn_date(period_start)
    chart_end = _vn_date(now)

    daily_counts: dict[date, int] = {}
    daily_cost: dict[date, float] = {}
    for r in current_rows:
        d = _vn_date(r["created_at"])
        daily_counts[d] = daily_counts.get(d, 0) + 1
        daily_cost[d] = daily_cost.get(d, 0) + float(r["estimated_cost_usd"] or 0)

    ai_turns_daily: list[DailyPoint] = []
    avg_cost_daily: list[DailyPoint] = []
    d = chart_start
    while d <= chart_end:
        ds = d.isoformat()
        ai_turns_daily.append(DailyPoint(date=ds, value=daily_counts.get(d, 0)))
        avg_cost_daily.append(DailyPoint(date=ds, value=round(daily_cost.get(d, 0), 4)))
        d += timedelta(days=1)

    intent_map: dict[str, int] = {}
    tier_map: dict[str, int] = {}
    for r in current_rows:
        intent = (r["intent"] or "unknown").strip() or "unknown"
        tier = (r["tier"] or "unknown").strip() or "unknown"
        intent_map[intent] = intent_map.get(intent, 0) + 1
        tier_map[tier] = tier_map.get(tier, 0) + 1

    current_turns = len(current_rows)
    previous_turns = len(previous_rows)
    current_cost = sum(float(r["estimated_cost_usd"] or 0) for r in current_rows)
    previous_cost = sum(float(r["estimated_cost_usd"] or 0) for r in previous_rows)

    sparkline = ai_turns_daily[-14:]

    return AiDashboardOverview(
        generated_at=now.isoformat(),
        days=days,
        total_turns=KpiMetric(
            value=current_turns,
            previous_value=previous_turns,
            delta_percent=_delta_pct(current_turns, previous_turns),
            sparkline=sparkline,
        ),
        estimated_cost_usd=KpiMetric(
            value=round(current_cost, 4),
            previous_value=round(previous_cost, 4),
            delta_percent=_delta_pct(current_cost, previous_cost),
        ),
        ai_turns_daily=ai_turns_daily,
        intent_distribution=[
            NamedCount(name=k, count=v)
            for k, v in sorted(intent_map.items(), key=lambda x: -x[1])
        ],
        model_tier_distribution=[
            NamedCount(name=k, count=v)
            for k, v in sorted(tier_map.items(), key=lambda x: -x[1])
        ],
        avg_cost_daily=avg_cost_daily,
    )
