"""Batch insight worker — compute AI scores for active users (CLI/cron)."""
from __future__ import annotations

import argparse
import asyncio

from app.logging_setup import get_logger, setup_logging
from app.tools.context import ToolRunContext
from app.tools.local import compute_and_update_ai_scores

_log = get_logger("ai.worker.insight")


async def process_user(user_id: str) -> None:
    ctx = ToolRunContext(user_id=user_id, state={})
    try:
        result = await compute_and_update_ai_scores(ctx)
        _log.info("insight_scores_updated", extra={"user_id": user_id, "result": str(result)[:200]})
    except Exception as exc:
        _log.warning("insight_user_failed", extra={"user_id": user_id, "error": str(exc)})


async def run_batch(user_ids: list[str]) -> None:
    for uid in user_ids:
        await process_user(uid)


async def run_from_iam_seed_demo() -> None:
    """Dev helper: no user list endpoint — caller passes IDs via CLI."""
    _log.info("insight_batch_ready", extra={"node": "worker"})


def main() -> None:
    parser = argparse.ArgumentParser(description="SYNC AI insight batch worker")
    parser.add_argument("--user-id", action="append", dest="user_ids", default=[])
    args = parser.parse_args()
    setup_logging("INFO")
    if not args.user_ids:
        asyncio.run(run_from_iam_seed_demo())
        return
    asyncio.run(run_batch(args.user_ids))


if __name__ == "__main__":
    main()
