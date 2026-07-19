"""Audit log mỗi turn — phục vụ AIReasoningSnapshotJson + truy vết bảo mật.

KHÔNG ghi PII thô; chỉ ghi metadata suy luận (intent, tier, tokens, cost, flags,
tool đã gọi). Có thể ghi ra log JSON và/hoặc Postgres tuỳ cấu hình.
"""
from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field

from app.logging_setup import get_logger
from app.observability.flow_log import flow_data

_log = get_logger("ai.audit")
_table_ready = False

_CREATE_AI_TURN_AUDIT = """
CREATE TABLE IF NOT EXISTS ai_turn_audit (
    id                      BIGSERIAL PRIMARY KEY,
    trace_id                UUID        NOT NULL,
    user_id                 UUID        NOT NULL,
    session_id              TEXT        NOT NULL,
    intent                  TEXT,
    tier                    TEXT,
    locale                  TEXT,
    tokens_used             INT         DEFAULT 0,
    estimated_cost_usd      NUMERIC(10,6) DEFAULT 0,
    guardrail_flags         JSONB,
    requires_confirmation   BOOLEAN     DEFAULT false,
    cache_hit               BOOLEAN     DEFAULT false,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
)
"""


@dataclass
class TurnAudit:
    trace_id: str
    user_id: str
    session_id: str
    intent: str
    tier: str
    locale: str
    tokens_used: int
    estimated_cost_usd: float
    guardrail_flags: list[str] = field(default_factory=list)
    tools_called: list[str] = field(default_factory=list)
    requires_confirmation: bool = False
    cache_hit: bool = False

    def to_reasoning_snapshot(self) -> str:
        """JSON gọn để lưu Order.AIReasoningSnapshotJson / Transaction.AIReasoningSnapshotJson."""
        return json.dumps(asdict(self), ensure_ascii=False)


def write_audit(audit: TurnAudit) -> None:
    _log.info(
        "turn_audit",
        extra={
            "trace_id": audit.trace_id,
            "user_id": audit.user_id,
            "session_id": audit.session_id,
            "intent": audit.intent,
            "tier": audit.tier,
        },
    )
    flow_data(
        "Audit turn",
        {
            "intent": audit.intent,
            "tier": audit.tier,
            "tokens": audit.tokens_used,
            "tools": audit.tools_called,
            "flags": audit.guardrail_flags,
            "confirm": audit.requires_confirmation,
        },
        indent=2,
    )


async def _ensure_table(pool) -> bool:
    global _table_ready
    if _table_ready:
        return True
    try:
        await pool.execute(_CREATE_AI_TURN_AUDIT)
        await pool.execute(
            "CREATE INDEX IF NOT EXISTS idx_ai_turn_audit_user "
            "ON ai_turn_audit(user_id, created_at DESC)"
        )
        _table_ready = True
        return True
    except Exception as exc:
        _log.debug("ai_turn_audit ensure_table skipped: %s", exc)
        return False


async def persist_turn_audit(audit: TurnAudit) -> None:
    """Ghi audit vào Postgres (best-effort)."""
    from app.deps import get_pg_pool

    pool = get_pg_pool()
    if pool is None:
        return
    try:
        import uuid

        if not await _ensure_table(pool):
            return

        await pool.execute(
            """
            INSERT INTO ai_turn_audit (
                trace_id, user_id, session_id, intent, tier, locale,
                tokens_used, estimated_cost_usd, guardrail_flags,
                requires_confirmation, cache_hit
            ) VALUES (
                $1::uuid, $2::uuid, $3, $4, $5, $6,
                $7, $8, $9::jsonb, $10, $11
            )
            """,
            uuid.UUID(audit.trace_id),
            uuid.UUID(audit.user_id),
            audit.session_id,
            audit.intent,
            audit.tier,
            audit.locale,
            audit.tokens_used,
            audit.estimated_cost_usd,
            json.dumps(audit.guardrail_flags),
            audit.requires_confirmation,
            audit.cache_hit,
        )
    except Exception as exc:
        _log.debug(
            "persist_turn_audit_failed: %s",
            exc,
            extra={"trace_id": audit.trace_id},
        )
