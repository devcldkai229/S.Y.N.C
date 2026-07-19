"""RabbitMQ event consumer — proactive AI interventions."""
from __future__ import annotations

import asyncio
import json
from typing import Any

from app.integrations import signalr
from app.logging_setup import get_logger
from app.tools.context import ToolRunContext
from app.tools.local import detect_burnout

_log = get_logger("ai.events")

SUBSCRIBED_EVENTS = (
    "OrderPlacedEvent",
    "OrderCompletedEvent",
    "OrderStatusChangedEvent",
    "WorkoutCompletedEvent",
    "WorkoutSkippedEvent",
    "MealLoggedEvent",
)


async def handle_event(event_type: str, payload: dict[str, Any]) -> None:
    user_id = str(payload.get("UserId") or payload.get("userId") or "")
    if not user_id:
        return

    ctx = ToolRunContext(user_id=user_id, state={})

    if event_type == "WorkoutSkippedEvent":
        await signalr.push_proactive_message(
            user_id,
            title="SYNC AI",
            body="Bạn bỏ lỡ buổi tập hôm nay — mai mình điều chỉnh nhẹ nhàng nhé?",
            deep_link="sync://roadmap/today",
        )
    elif event_type == "OrderCompletedEvent":
        await signalr.push_proactive_message(
            user_id,
            title="Đơn hàng đã giao",
            body="Nhớ log bữa ăn để theo dõi macro chính xác nhé!",
            deep_link="sync://nutrition/log",
        )
    elif event_type == "MealLoggedEvent":
        burnout = await detect_burnout(ctx)
        if float(burnout.get("burnoutRiskScore") or 0) > 0.65:
            await signalr.push_proactive_message(
                user_id,
                title="Nghỉ ngơi nhé",
                body="Mình thấy bạn hơi căng — cân nhắc giảm cường độ tập.",
                deep_link="sync://coach",
            )
    elif event_type in ("OrderPlacedEvent", "OrderStatusChangedEvent"):
        _log.info("event_ignored_light", extra={"type": event_type, "user_id": user_id})


async def _on_message(message: Any) -> None:
    try:
        body = json.loads(message.body.decode())
        event_type = body.get("eventType") or body.get("EventType") or message.routing_key
        await handle_event(event_type, body)
        await message.ack()
    except Exception:
        _log.exception("event_handler_error")
        await message.reject(requeue=False)


async def run_consumer(amqp_url: str | None = None) -> None:
    """Connect to RabbitMQ and consume AI intervention queue."""
    from app.config import get_settings

    url = amqp_url or get_settings().amqp_url

    try:
        import aio_pika

        connection = await aio_pika.connect_robust(url)
        channel = await connection.channel()
        queue = await channel.declare_queue("sync.ai.interventions", durable=True)
        await queue.consume(_on_message)
        _log.info("rabbitmq_consumer_started", extra={"queue": "sync.ai.interventions"})
        await asyncio.Future()
    except Exception:
        _log.warning("rabbitmq_unavailable_stub_mode")
        while True:
            await asyncio.sleep(3600)


if __name__ == "__main__":
    asyncio.run(run_consumer())
